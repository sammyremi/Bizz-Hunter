# frozen_string_literal: true

require 'test_helper'

class JobsQualificationAndPersistenceTest < ActiveSupport::TestCase
  def setup
    load Rails.root.join('db', 'seeds', 'jobs_geographic_catalog.rb')

    @user = User.create!(
      name: 'Qualification Tester',
      email: "qual_#{SecureRandom.hex(4)}@example.com",
      password: 'StrongPassword123!'
    )
    @country = Country.find_by!(iso_country_code: 'NG')
    @lagos = @country.country_cities.find_by!(name: 'Lagos')

    @job = Job.create!(
      user: @user,
      name: 'Web Dev Prospecting Job',
      status: 'active',
      outreach_mode: 'manual_review',
      website_targeting: 'no_website',
      daily_discovery_target: 50,
      daily_outreach_target: 10,
      discovery_window_start: '00:00:00',
      discovery_window_end: '23:59:59',
      active_weekdays: [1, 2, 3, 4, 5, 6, 7],
      message_template: 'Hi {{business_name}}'
    )

    @target = @job.job_targets.create!(
      country: @country,
      country_city: @lagos,
      category: 'dentist'
    )

    @lease_token = @target.lease!(5.minutes)
  end

  # 1. New unique business creates a Prospect
  test 'new unique business creates a Prospect record for the user' do
    raw_places = [
      {
        'id' => 'place_dentist_001',
        'displayName' => { 'text' => 'Lagos Smile Clinic' },
        'formattedAddress' => '12 Marina Road, Lagos',
        'internationalPhoneNumber' => '+2348011112222',
        'websiteUri' => nil
      }
    ]

    result = Jobs::QualifyAndPersistPlaces.call(
      job: @job,
      target: @target,
      raw_places: raw_places,
      lease_token: @lease_token
    )

    assert result[:success]
    assert_equal 1, result[:stats][:unique_new_count]
    assert_equal 0, result[:stats][:duplicate_count]
    assert_equal 1, result[:stats][:qualified_count]

    prospect = Prospect.find_by(user: @user, google_place_id: 'place_dentist_001')
    assert_not_nil prospect
    assert_equal 'Lagos Smile Clinic', prospect.business_name
    assert_equal '+2348011112222', prospect.international_phone_number
    assert_nil prospect.website

    job_prospect = @job.job_prospects.find_by(prospect: prospect)
    assert_not_nil job_prospect
    assert_equal 'qualified', job_prospect.qualification_status
    assert_equal 'no_website_found', job_prospect.website_status
  end

  # 2. Existing Prospect is reused
  test 'existing Prospect for user is reused and enriched without overwriting existing data' do
    existing = @user.prospects.create!(
      business_name: 'Existing Dental Clinic',
      google_place_id: 'place_dentist_002',
      address: 'Old Address',
      phone_number: '123456',
      status: 'CONTACTED'
    )

    raw_places = [
      {
        'id' => 'place_dentist_002',
        'displayName' => { 'text' => 'Updated Clinic Name' },
        'formattedAddress' => 'New Address',
        'internationalPhoneNumber' => '+2348099998888',
        'websiteUri' => nil
      }
    ]

    result = Jobs::QualifyAndPersistPlaces.call(
      job: @job,
      target: @target,
      raw_places: raw_places,
      lease_token: @lease_token
    )

    assert result[:success]
    assert_equal 0, result[:stats][:unique_new_count]
    assert_equal 1, result[:stats][:duplicate_count]

    # Reused the existing prospect
    assert_equal 1, Prospect.where(user: @user, google_place_id: 'place_dentist_002').count
    existing.reload
    assert_equal 'Existing Dental Clinic', existing.business_name
    assert_equal 'Old Address', existing.address # Not overwritten
    assert_equal 'CONTACTED', existing.status # Preserved status
    assert_equal '+2348099998888', existing.international_phone_number # Enriched blank field
  end

  # 3. Duplicate Google Place ID does not create another Prospect
  test 'duplicate Google Place ID does not create another Prospect record' do
    raw_places = [
      { 'id' => 'place_dup_001', 'displayName' => { 'text' => 'Dup 1' }, 'websiteUri' => nil },
      { 'id' => 'place_dup_001', 'displayName' => { 'text' => 'Dup 1 Repeat' }, 'websiteUri' => nil }
    ]

    result = Jobs::QualifyAndPersistPlaces.call(
      job: @job,
      target: @target,
      raw_places: raw_places,
      lease_token: @lease_token
    )

    assert result[:success]
    assert_equal 1, result[:stats][:unique_new_count]
    assert_equal 1, result[:stats][:duplicate_count]
    assert_equal 1, Prospect.where(user: @user, google_place_id: 'place_dup_001').count
  end

  # 4. One Prospect can belong to multiple Jobs
  test 'one Prospect can belong to multiple Jobs through distinct JobProspect associations' do
    job2 = Job.create!(
      user: @user,
      name: 'Second Job',
      status: 'active',
      outreach_mode: 'manual_review',
      website_targeting: 'both',
      daily_discovery_target: 20,
      daily_outreach_target: 5,
      discovery_window_start: '00:00:00',
      discovery_window_end: '23:59:59',
      active_weekdays: [1, 2, 3, 4, 5, 6, 7],
      message_template: 'Hello'
    )
    target2 = job2.job_targets.create!(country: @country, country_city: @lagos, category: 'hospital')
    lease2 = target2.lease!(5.minutes)

    raw_places = [{ 'id' => 'shared_place_001', 'displayName' => { 'text' => 'Shared Clinic' }, 'websiteUri' => nil }]

    # Process in Job 1
    Jobs::QualifyAndPersistPlaces.call(job: @job, target: @target, raw_places: raw_places, lease_token: @lease_token)
    # Process in Job 2
    res2 = Jobs::QualifyAndPersistPlaces.call(job: job2, target: target2, raw_places: raw_places, lease_token: lease2)

    assert res2[:success]
    assert_equal 1, Prospect.where(user: @user, google_place_id: 'shared_place_001').count
    prospect = Prospect.find_by(user: @user, google_place_id: 'shared_place_001')

    assert_equal 2, prospect.job_prospects.count
    assert_equal 1, @job.job_prospects.where(prospect: prospect).count
    assert_equal 1, job2.job_prospects.where(prospect: prospect).count
  end

  # 5. Duplicate JobProspect association is prevented
  test 'duplicate JobProspect association on the same job is prevented' do
    raw_places = [{ 'id' => 'place_once_001', 'displayName' => { 'text' => 'Once Clinic' }, 'websiteUri' => nil }]

    # First run
    Jobs::QualifyAndPersistPlaces.call(job: @job, target: @target, raw_places: raw_places, lease_token: @lease_token)
    # Second run with same place
    Jobs::QualifyAndPersistPlaces.call(job: @job, target: @target, raw_places: raw_places, lease_token: @lease_token)

    prospect = Prospect.find_by(user: @user, google_place_id: 'place_once_001')
    assert_equal 1, @job.job_prospects.where(prospect: prospect).count
  end

  # 6. Missing website is not automatically classified as confirmed no website
  test 'missing website from Google Places payload is classified as unknown if websiteUri not present' do
    # When Google Places payload did not include website field at all
    raw_places = [
      {
        'id' => 'place_no_key_001',
        'displayName' => { 'text' => 'Mystery Business' }
        # Note: no 'websiteUri' key present
      }
    ]

    result = Jobs::QualifyAndPersistPlaces.call(
      job: @job,
      target: @target,
      raw_places: raw_places,
      lease_token: @lease_token
    )

    assert result[:success]
    prospect = Prospect.find_by(user: @user, google_place_id: 'place_no_key_001')
    jp = @job.job_prospects.find_by(prospect: prospect)

    assert_equal 'unknown', jp.website_status
    # For no_website targeting, unknown websites become 'pending_criteria' (not disqualified or false qualified)
    assert_equal 'pending_criteria', jp.qualification_status
  end

  # 7. Each website criterion behaves correctly
  test 'website criteria: no_website qualifies no_website_found and disqualifies website_found' do
    @job.update_columns(website_targeting: 'no_website')

    raw_places = [
      { 'id' => 'p_no_web', 'displayName' => { 'text' => 'No Web' }, 'websiteUri' => nil },
      { 'id' => 'p_has_web', 'displayName' => { 'text' => 'Has Web' }, 'websiteUri' => 'https://example.com' }
    ]

    result = Jobs::QualifyAndPersistPlaces.call(
      job: @job,
      target: @target,
      raw_places: raw_places,
      lease_token: @lease_token
    )

    assert result[:success]
    assert_equal 1, result[:stats][:qualified_count]
    assert_equal 1, result[:stats][:disqualified_count]

    jp_no_web = @job.job_prospects.find_by(prospect: Prospect.find_by(google_place_id: 'p_no_web'))
    jp_has_web = @job.job_prospects.find_by(prospect: Prospect.find_by(google_place_id: 'p_has_web'))

    assert_equal 'qualified', jp_no_web.qualification_status
    assert_equal 'no_website_found', jp_no_web.website_status

    assert_equal 'disqualified', jp_has_web.qualification_status
    assert_equal 'website_found', jp_has_web.website_status
  end

  test 'website criteria: weak_or_outdated sets pending_criteria for website_found and disqualifies no_website' do
    @job.update_columns(website_targeting: 'weak_or_outdated')

    raw_places = [
      { 'id' => 'p_no_web_2', 'displayName' => { 'text' => 'No Web' }, 'websiteUri' => nil },
      { 'id' => 'p_has_web_2', 'displayName' => { 'text' => 'Has Web' }, 'websiteUri' => 'https://example.com' }
    ]

    result = Jobs::QualifyAndPersistPlaces.call(
      job: @job,
      target: @target,
      raw_places: raw_places,
      lease_token: @lease_token
    )

    assert result[:success]
    jp_no_web = @job.job_prospects.find_by(prospect: Prospect.find_by(google_place_id: 'p_no_web_2'))
    jp_has_web = @job.job_prospects.find_by(prospect: Prospect.find_by(google_place_id: 'p_has_web_2'))

    assert_equal 'disqualified', jp_no_web.qualification_status
    assert_equal 'pending_criteria', jp_has_web.qualification_status
  end

  test 'website criteria: both qualifies businesses regardless of website presence' do
    @job.update_columns(website_targeting: 'both')

    raw_places = [
      { 'id' => 'p_no_web_3', 'displayName' => { 'text' => 'No Web' }, 'websiteUri' => nil },
      { 'id' => 'p_has_web_3', 'displayName' => { 'text' => 'Has Web' }, 'websiteUri' => 'https://example.com' }
    ]

    result = Jobs::QualifyAndPersistPlaces.call(
      job: @job,
      target: @target,
      raw_places: raw_places,
      lease_token: @lease_token
    )

    assert result[:success]
    assert_equal 2, result[:stats][:qualified_count]
    assert_equal 0, result[:stats][:disqualified_count]
  end

  # 8. Stale workers cannot modify records after losing their lease
  test 'stale worker cannot persist places if lease expired or belongs to another worker' do
    # Worker 1's lease expires
    @target.update_columns(lease_expires_at: 1.second.ago)

    raw_places = [{ 'id' => 'place_stale_001', 'displayName' => { 'text' => 'Stale Clinic' }, 'websiteUri' => nil }]

    result = Jobs::QualifyAndPersistPlaces.call(
      job: @job,
      target: @target,
      raw_places: raw_places,
      lease_token: @lease_token
    )

    assert_not result[:success]
    assert_equal :lease_lost, result[:reason]
    assert_nil Prospect.find_by(user: @user, google_place_id: 'place_stale_001')
  end

  # 9. Safety exception handler in ExecuteDiscovery passes lease_token to release_lease!
  test 'unexpected exception in ExecuteDiscovery passes lease_token to release_lease!' do
    target = @job.job_targets.create!(country: @country, country_city: @lagos, category: 'hospital')

    # Mock Jobs::QualifyAndPersistPlaces to raise a StandardError simulating an unhandled failure in execution
    singleton = Jobs::QualifyAndPersistPlaces.singleton_class
    original_call = Jobs::QualifyAndPersistPlaces.method(:call)
    singleton.send(:define_method, :call) do |*args, **kwargs|
      raise StandardError, 'Unexpected database serialization failure'
    end

    begin
      assert_nothing_raised do
        result = Jobs::ExecuteDiscovery.call(job: @job, target: target)
        assert_not result[:success]
        assert_equal :error, result[:reason]
      end
    ensure
      singleton.send(:define_method, :call, original_call)
    end

    # Target lease is safely released without crashing or wiping others
    target.reload
    assert_nil target.lease_token
    assert_nil target.lease_expires_at
  end

  # 10. Quota uses unique_new_businesses rather than raw API results
  test 'QuotaReservation.reserve! measures against unique_new_businesses' do
    stat_date = Time.current.in_time_zone(@job.timezone).to_date
    @job.update_columns(daily_discovery_target: 10)

    # 8 raw businesses found, but only 2 unique new businesses recorded
    JobDailyStat.increment_stat!(job_id: @job.id, stat_date: stat_date, field: :businesses_found, count: 8)
    JobDailyStat.increment_stat!(job_id: @job.id, stat_date: stat_date, field: :unique_new_businesses, count: 2)

    # Reserving 5 more should succeed because 2 unique + 5 = 7 <= 10 (even though raw = 8 + 5 = 13 > 10)
    res = QuotaReservation.reserve!(job: @job, quota_type: 'discovery', amount: 5)
    assert res[:success]

    # Reserving 4 more should now fail because 2 consumed + 5 active_reserved + 4 = 11 > 10
    res_fail = QuotaReservation.reserve!(job: @job, quota_type: 'discovery', amount: 4)
    assert_not res_fail[:success]
    assert_includes res_fail[:message], 'Daily discovery limit'
  end
end
