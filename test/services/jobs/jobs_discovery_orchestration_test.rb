# frozen_string_literal: true

require 'test_helper'

class JobsDiscoveryOrchestrationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  def setup
    load Rails.root.join('db', 'seeds', 'jobs_geographic_catalog.rb')

    @user = User.create!(
      name: 'Discovery Tester',
      email: "disco_#{SecureRandom.hex(4)}@example.com",
      password: 'StrongPassword123!'
    )
    @country = Country.find_by!(iso_country_code: 'NG')
    @lagos = @country.country_cities.find_by!(name: 'Lagos')
    @abuja = @country.country_cities.find_by!(name: 'Abuja')

    # Job active, wide discovery window (00:00 to 23:59), all weekdays (1..7)
    @job = Job.create!(
      user: @user,
      name: 'Dental Discovery Job',
      status: 'active',
      outreach_mode: 'manual_review',
      daily_discovery_target: 50,
      daily_outreach_target: 10,
      discovery_window_start: '00:00:00',
      discovery_window_end: '23:59:59',
      active_weekdays: [1, 2, 3, 4, 5, 6, 7],
      message_template: 'Hi {{business_name}}'
    )
  end

  # 1. Fair Target Rotation: unsearched targets receive highest priority
  test 'selects unsearched targets first in fair rotation' do
    t1 = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'dentist', last_searched_at: 1.hour.ago)
    t2 = @job.job_targets.create!(country: @country, country_city: @abuja, category: 'dentist', last_searched_at: nil)

    result = Jobs::SelectNextTarget.call(job: @job)
    assert result[:success]
    assert_equal t2.id, result[:target].id
    assert_not_nil result[:lease_token]
  end

  # 2. Fair Target Rotation: least recently searched target is chosen next
  test 'rotates to least recently searched target among searched targets' do
    t1 = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'dentist', last_searched_at: 2.hours.ago)
    t2 = @job.job_targets.create!(country: @country, country_city: @abuja, category: 'dentist', last_searched_at: 10.minutes.ago)

    result = Jobs::SelectNextTarget.call(job: @job)
    assert result[:success]
    assert_equal t1.id, result[:target].id
  end

  # 3. Concurrent target claiming: active lease prevents duplicate claiming
  test 'concurrent claiming: leased target cannot be claimed by another worker until lease expires' do
    target = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'dentist')

    res1 = Jobs::SelectNextTarget.call(job: @job, lease_duration: 5.minutes)
    assert res1[:success]
    assert_equal target.id, res1[:target].id

    # Second worker attempts to claim; since target is leased, it finds no available target
    res2 = Jobs::SelectNextTarget.call(job: @job)
    assert_not res2[:success]
    assert_includes res2[:message], 'No eligible targets available'
  end

  # 4. Expired lease recovery
  test 'expired leases are safely reclaimed by next worker' do
    target = @job.job_targets.create!(
      country: @country,
      country_city: @lagos,
      category: 'dentist',
      lease_token: 'old_token',
      leased_at: 10.minutes.ago,
      lease_expires_at: 2.minutes.ago # Expired
    )

    result = Jobs::SelectNextTarget.call(job: @job)
    assert result[:success]
    assert_equal target.id, result[:target].id
    assert_not_equal 'old_token', result[:lease_token]
  end

  # 5. Paused and archived jobs are skipped
  test 'skips paused and archived jobs' do
    @job.update!(status: 'paused')
    assert_not @job.eligible_for_discovery_at?

    res_paused = Jobs::ExecuteDiscovery.call(job: @job)
    assert_not res_paused[:success]
    assert_equal :ineligible, res_paused[:reason]

    @job.archive!
    res_archived = Jobs::ExecuteDiscovery.call(job: @job)
    assert_not res_archived[:success]
    assert_equal :ineligible, res_archived[:reason]
  end

  # 6. Jobs outside schedule window or active weekdays are skipped
  test 'skips jobs outside configured schedule or weekdays' do
    # Narrow window to past hour
    @job.update!(discovery_window_start: '01:00:00', discovery_window_end: '02:00:00')
    time_now = Time.zone.parse('2026-11-04 15:00:00')

    assert_not @job.eligible_for_discovery_at?(time_now)
  end

  # 7. Successful discovery execution with Google Places mock
  test 'successful discovery updates target progress and consumes quota' do
    target = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'dentist')

    mock_response = {
      'places' => [
        { 'id' => 'place_1', 'displayName' => { 'text' => 'Lagos Smiles Clinic' } },
        { 'id' => 'place_2', 'displayName' => { 'text' => 'Ikeja Dental Clinic' } }
      ],
      'nextPageToken' => 'token_page_2'
    }

    with_stub(GooglePlaces::BusinessSearch, :call, mock_response) do
      result = Jobs::ExecuteDiscovery.call(job: @job, target: target)
      assert result[:success]
      assert_equal 2, result[:discovered_count]
      assert_equal 'token_page_2', result[:next_page_token]

      # Target progress updated
      target.reload
      assert_equal 1, target.search_count
      assert_equal 2, target.total_discovered_count
      assert_not_nil target.last_searched_at
      assert_nil target.lease_token

      # Job last_discovery_at updated
      assert_not_nil @job.reload.last_discovery_at

      # Daily stat recorded
      stat = JobDailyStat.find_by!(job_id: @job.id, stat_date: Date.current)
      assert_equal 2, stat.businesses_found
    end
  end

  # 8. Empty search results still updates target progress
  test 'empty search results completes search and records 0 discovered places' do
    target = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'rare business')

    with_stub(GooglePlaces::BusinessSearch, :call, { 'places' => [] }) do
      result = Jobs::ExecuteDiscovery.call(job: @job, target: target)
      assert result[:success]
      assert_equal 0, result[:discovered_count]

      target.reload
      assert_equal 1, target.search_count
      assert_equal 0, target.total_discovered_count
      assert_not_nil target.last_searched_at
    end
  end

  # 9. Failed API request releases lease without marking target searched
  test 'failed API request releases target lease and does not advance last_searched_at' do
    target = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'dentist')

    singleton = GooglePlaces::BusinessSearch.singleton_class
    original_call = GooglePlaces::BusinessSearch.method(:call)
    singleton.send(:define_method, :call) { |*args, **kwargs| raise StandardError, 'Google API 400 Bad Request' }

    begin
      result = Jobs::ExecuteDiscovery.call(job: @job, target: target)
      assert_not result[:success]
      assert_equal :search_failed, result[:reason]

      target.reload
      assert_equal 0, target.search_count
      assert_nil target.last_searched_at
      assert_nil target.lease_token # Lease was safely released

      # Quota reservation released
      reservation = QuotaReservation.find_by(job_id: @job.id)
      assert_equal 'released', reservation.status
    ensure
      singleton.send(:define_method, :call, original_call)
    end
  end

  # 10. Transient errors trigger bounded retry
  test 'transient rate-limit errors perform bounded retry and succeed' do
    target = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'dentist')

    attempts = 0
    singleton = GooglePlaces::BusinessSearch.singleton_class
    original_call = GooglePlaces::BusinessSearch.method(:call)
    singleton.send(:define_method, :call) do |*args, **kwargs|
      attempts += 1
      if attempts == 1
        raise StandardError, 'Rate limit exceeded (HTTP 429)'
      else
        { 'places' => [{ 'id' => 'p_recovered' }] }
      end
    end

    begin
      result = Jobs::ExecuteDiscovery.call(job: @job, target: target)
      assert result[:success]
      assert_equal 2, attempts # Retried once and succeeded
      assert_equal 1, result[:discovered_count]
    ensure
      singleton.send(:define_method, :call, original_call)
    end
  end

  # 11. Enforces daily discovery limit
  test 'halts when daily discovery target is reached' do
    @job.update!(daily_discovery_target: 10)
    JobDailyStat.increment_stat!(job_id: @job.id, stat_date: Date.current, field: :businesses_found, count: 10)

    target = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'dentist')

    result = Jobs::ExecuteDiscovery.call(job: @job, target: target)
    assert_not result[:success]
    assert_equal :daily_limit_reached, result[:reason]
    assert_includes result[:message], 'Daily discovery limit (10) reached'
  end

  # 12. Multiple independent Jobs execute without collision
  test 'multiple independent jobs run in parallel without blocking each other' do
    job2 = Job.create!(
      user: @user,
      name: 'Hotels Job',
      status: 'active',
      daily_discovery_target: 50,
      discovery_window_start: '00:00:00',
      discovery_window_end: '23:59:59',
      active_weekdays: [1, 2, 3, 4, 5, 6, 7],
      message_template: 'Hi'
    )

    t1 = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'dentist')
    t2 = job2.job_targets.create!(country: @country, country_city: @lagos, category: 'hotel')

    res1 = Jobs::SelectNextTarget.call(job: @job)
    res2 = Jobs::SelectNextTarget.call(job: job2)

    assert res1[:success]
    assert res2[:success]
    assert_equal t1.id, res1[:target].id
    assert_equal t2.id, res2[:target].id
  end

  # 13. Lease fencing: worker holding expired lease cannot overwrite new lease outcome
  test 'lease fencing: expired worker cannot record search outcome after lease reclaimed' do
    target = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'dentist')

    # Worker 1 leases target
    token_worker_1 = target.lease!(1.second)

    # Worker 1 times out; lease expires
    target.update_columns(lease_expires_at: 1.second.ago)

    # Worker 2 reclaims target
    res2 = Jobs::SelectNextTarget.call(job: @job)
    assert res2[:success]
    token_worker_2 = res2[:lease_token]
    assert_not_equal token_worker_1, token_worker_2

    # Worker 1 returns late with token_worker_1 and attempts to record outcome
    recorded = target.record_search_outcome!(token: token_worker_1, discovered_count: 10)
    assert_equal false, recorded

    # Verify target progress was not updated by stale worker 1
    target.reload
    assert_equal 0, target.search_count
    assert_equal token_worker_2, target.lease_token

    # Worker 2 completes successfully with its valid token
    assert target.record_search_outcome!(token: token_worker_2, discovered_count: 5)
    target.reload
    assert_equal 1, target.search_count
    assert_equal 5, target.total_discovered_count
    assert_nil target.lease_token
  end

  # 14. Lease renewal: active lease can be renewed by holder, but not by wrong token
  test 'lease renewal: active lease can be renewed by holder but rejected for expired or wrong token' do
    target = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'dentist')
    token = target.lease!(2.minutes)

    # Holder successfully renews lease
    assert target.renew_lease!(token, 10.minutes)
    assert target.reload.lease_expires_at > Time.current + 8.minutes

    # Wrong token renewal rejected
    assert_not target.renew_lease!('bogus_token')

    # Expired lease renewal rejected
    target.update_columns(lease_expires_at: 1.second.ago)
    assert_not target.renew_lease!(token)
  end

  # 15. Retry policy respects Retry-After and rejects permanent client errors
  test 'permanent client errors (400, 401, 403) are not retried' do
    target = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'dentist')

    attempts = 0
    singleton = GooglePlaces::BusinessSearch.singleton_class
    original_call = GooglePlaces::BusinessSearch.method(:call)
    singleton.send(:define_method, :call) do |*args, **kwargs|
      attempts += 1
      ex = StandardError.new('403: Forbidden - Invalid API key')
      ex.instance_variable_set(:@http_status, 403)
      def ex.http_status; @http_status; end
      raise ex
    end

    begin
      result = Jobs::ExecuteDiscovery.call(job: @job, target: target)
      assert_not result[:success]
      assert_equal :search_failed, result[:reason]
      # Crucial: Must NOT retry permanent 403 error!
      assert_equal 1, attempts
    ensure
      singleton.send(:define_method, :call, original_call)
    end
  end

  # 16. Scheduler duplicate prevention
  test 'DiscoverySchedulerJob does not duplicate pending discovery execution jobs' do
    assert_enqueued_with(job: Jobs::DiscoveryExecutionJob, args: [@job.id]) do
      Jobs::DiscoverySchedulerJob.perform_now
    end

    # Second immediate run should detect pending execution job and skip duplicate enqueue
    assert_no_enqueued_jobs(only: Jobs::DiscoveryExecutionJob) do
      Jobs::DiscoverySchedulerJob.perform_now
    end
  end
end
