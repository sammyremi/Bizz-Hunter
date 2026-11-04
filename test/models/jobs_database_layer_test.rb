# frozen_string_literal: true

require 'test_helper'

class JobsDatabaseLayerTest < ActiveSupport::TestCase
  def setup
    load Rails.root.join('db', 'seeds', 'jobs_geographic_catalog.rb')
    @user = User.create!(
      name: 'Test Agency Owner',
      email: "agency_#{SecureRandom.hex(4)}@example.com",
      password: 'StrongPassword123!'
    )
    @other_user = User.create!(
      name: 'Other User',
      email: "other_#{SecureRandom.hex(4)}@example.com",
      password: 'StrongPassword123!'
    )
    @profile = ProspectingProfile.create!(
      user: @user,
      name: 'Web Dev for Clinics',
      service: 'Web Development',
      service_description: 'We build modern websites'
    )
    @other_profile = ProspectingProfile.create!(
      user: @other_user,
      name: 'Foreign Profile',
      service: 'SEO',
      service_description: 'SEO optimization'
    )
    @prospect = Prospect.create!(
      user: @user,
      google_place_id: "place_#{SecureRandom.hex(8)}",
      business_name: 'Alpha Dental Care',
      phone_number: '08012345678',
      status: 'NEW'
    )
    @country = Country.find_by!(iso_country_code: 'NG')
    @city = @country.country_cities.find_by!(name: 'Lagos')
  end

  test '1. geographic catalog contains exactly 10 launch countries and 200 cities' do
    assert_equal 10, Country.count
    assert_equal 200, CountryCity.count
    assert_equal 20, @country.country_cities.count
    assert_equal 20, @country.default_cities.count
    assert_equal '234', @country.calling_code
  end

  test '2. creates job with valid attributes and user ownership' do
    job = Job.new(
      user: @user,
      prospecting_profile: @profile,
      name: 'Dental Clinics Outreach',
      status: 'active',
      outreach_mode: 'manual_review',
      website_targeting: 'both',
      daily_discovery_target: 60,
      daily_outreach_target: 25,
      outreach_interval_seconds: 120,
      active_weekdays: [1, 2, 3, 4, 5],
      message_template: 'Hello {{business_name}}, we can build your website!'
    )

    assert job.valid?, job.errors.full_messages.to_sentence
    job.save!
    assert_not_nil job.id
    assert_equal false, job.archived?
  end

  test '3. prevents job association with a prospecting profile belonging to another user' do
    job = Job.new(
      user: @user,
      prospecting_profile: @other_profile,
      name: 'Invalid Ownership Job',
      message_template: 'Hello {{business_name}}'
    )

    assert_not job.valid?
    assert_includes job.errors[:prospecting_profile], 'must belong to the same user as the Job'
  end

  test '4. enforces weekday array validation (1..7)' do
    job = Job.new(
      user: @user,
      name: 'Invalid Weekday Job',
      active_weekdays: [0, 8],
      message_template: 'Hello {{business_name}}'
    )

    assert_not job.valid?
    assert_includes job.errors[:active_weekdays], 'must only contain integers between 1 (Monday) and 7 (Sunday)'
  end

  test '5. job targets support catalog cities and custom cities' do
    job = Job.create!(
      user: @user,
      name: 'Target Test Job',
      message_template: 'Hello {{business_name}}'
    )

    catalog_target = job.job_targets.create!(
      country: @country,
      country_city: @city,
      category: 'dental clinic'
    )
    assert catalog_target.persisted?
    assert_equal 'Lagos', catalog_target.city_name

    custom_target = job.job_targets.create!(
      country: @country,
      custom_city_name: 'Epe Town',
      category: 'restaurant'
    )
    assert custom_target.persisted?
    assert_equal 'Epe Town', custom_target.city_name

    # Enforces uniqueness for identical target combination
    duplicate_target = job.job_targets.build(
      country: @country,
      country_city: @city,
      category: 'dental clinic'
    )
    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate_target.save!(validate: false)
    end
  end

  test '6. associates prospect with job and prevents duplicate association' do
    job = Job.create!(
      user: @user,
      name: 'Job Prospect Assoc Job',
      message_template: 'Hello {{business_name}}'
    )

    jp = JobProspect.create!(
      job: job,
      prospect: @prospect,
      qualification_status: 'qualified',
      website_status: 'no_website_found',
      review_status: 'pending'
    )
    assert jp.persisted?

    # Duplicate association rejected
    duplicate_jp = JobProspect.new(
      job: job,
      prospect: @prospect
    )
    assert_not duplicate_jp.valid?
    assert_includes duplicate_jp.errors[:prospect_id], 'has already been associated with this Job'
  end

  test '7. prevents associating a prospect belonging to a different user' do
    foreign_prospect = Prospect.create!(
      user: @other_user,
      google_place_id: "foreign_place_#{SecureRandom.hex(8)}",
      business_name: 'Foreign Biz',
      status: 'NEW'
    )
    job = Job.create!(
      user: @user,
      name: 'User Isolation Job',
      message_template: 'Hello {{business_name}}'
    )

    jp = JobProspect.new(
      job: job,
      prospect: foreign_prospect
    )
    assert_not jp.valid?
    assert_includes jp.errors[:prospect], 'must belong to the same user as the Job'
  end

  test '8. outreach task queueing, claiming, and token verification' do
    job = Job.create!(
      user: @user,
      name: 'Outreach Queue Job',
      message_template: 'Hello {{business_name}}'
    )
    jp = JobProspect.create!(
      job: job,
      prospect: @prospect,
      qualification_status: 'qualified',
      review_status: 'approved'
    )

    reg = ExtensionDevice.register_device!(
      user: @user,
      client_name: 'Office Brave Laptop'
    )
    device = reg[:device]
    raw_api_key = reg[:raw_api_key]
    assert device.authenticate_api_key?(raw_api_key)

    idempotency_key = OutreachTask.build_idempotency_key(job_id: job.id, job_prospect_id: jp.id)
    task = OutreachTask.create!(
      job: job,
      job_prospect: jp,
      prepared_message: 'Hi Alpha Dental Care',
      destination_phone: '2348012345678',
      whatsapp_url: 'https://wa.me/2348012345678?text=Hi',
      idempotency_key: idempotency_key,
      status: 'queued'
    )
    assert task.persisted?

    # Claim task for device
    raw_dispatch_token = task.claim_for_device!(device)
    assert_equal 'dispatched', task.status
    assert_equal 1, task.attempt_count
    assert task.verify_dispatch_token(raw_dispatch_token)
    assert_not task.verify_dispatch_token('wrong-token')

    # Confirmation
    task.mark_sent!
    assert_equal 'sent', task.status
    assert_not_nil task.completed_at
  end

  test '9. safety: uncertain outreach tasks cannot be automatically retried' do
    job = Job.create!(
      user: @user,
      name: 'Uncertain Test Job',
      message_template: 'Hello {{business_name}}'
    )
    jp = JobProspect.create!(
      job: job,
      prospect: @prospect,
      qualification_status: 'qualified'
    )
    task = OutreachTask.create!(
      job: job,
      job_prospect: jp,
      prepared_message: 'Hi',
      destination_phone: '2348012345678',
      whatsapp_url: 'https://wa.me/2348012345678',
      idempotency_key: SecureRandom.hex(16),
      status: 'queued'
    )

    task.mark_uncertain!(error_details: 'Browser crashed before send receipt acknowledged')
    assert_equal 'uncertain', task.status
    assert_equal 'UNCERTAIN_DISPATCH_RESULT', task.error_code

    # Verify not included in ready_for_dispatch scope
    ready_tasks = OutreachTask.ready_for_dispatch
    assert_not_includes ready_tasks, task
  end

  test '10. job archiving preserves outreach history and prospect records' do
    job = Job.create!(
      user: @user,
      name: 'Archiving Test Job',
      message_template: 'Hello {{business_name}}'
    )
    jp = JobProspect.create!(
      job: job,
      prospect: @prospect,
      qualification_status: 'qualified'
    )
    task = OutreachTask.create!(
      job: job,
      job_prospect: jp,
      prepared_message: 'Hi Alpha Dental Care',
      destination_phone: '2348012345678',
      whatsapp_url: 'https://wa.me/2348012345678',
      idempotency_key: SecureRandom.hex(16),
      status: 'sent',
      completed_at: Time.current
    )

    job.archive!
    assert job.archived?
    assert_equal 'archived', job.status

    # Outreach history and prospect records remain intact
    assert_equal 1, job.outreach_tasks.count
    assert_equal 'sent', task.reload.status
    assert Prospect.exists?(@prospect.id)
  end

  test '11. concurrent-safe daily stats and quota reservations' do
    job = Job.create!(
      user: @user,
      name: 'Quota Test Job',
      daily_discovery_target: 50,
      daily_outreach_target: 10,
      message_template: 'Hello {{business_name}}'
    )

    today = Date.current
    JobDailyStat.increment_stat!(job_id: job.id, stat_date: today, field: :unique_new_businesses, count: 20)
    JobDailyStat.increment_stat!(job_id: job.id, stat_date: today, field: :unique_new_businesses, count: 15)

    stat = JobDailyStat.find_by!(job_id: job.id, stat_date: today)
    assert_equal 35, stat.unique_new_businesses

    # Test quota reservation
    res1 = QuotaReservation.reserve!(job: job, quota_type: 'discovery', amount: 10)
    assert res1[:success]
    assert_equal 10, res1[:reservation].amount

    # Attempt to exceed remaining quota (35 consumed + 10 reserved = 45; 10 more exceeds 50)
    res2 = QuotaReservation.reserve!(job: job, quota_type: 'discovery', amount: 10)
    assert_not res2[:success]
    assert_includes res2[:message], 'Daily discovery limit (50) reached'

    # Release reservation and re-attempt
    res1[:reservation].release!
    res3 = QuotaReservation.reserve!(job: job, quota_type: 'discovery', amount: 5)
    assert res3[:success]
  end

  test '12. deletion safety: cannot permanently delete job or job_prospect if outreach tasks exist' do
    job = Job.create!(
      user: @user,
      name: 'Deletion Safety Job',
      message_template: 'Hello {{business_name}}'
    )
    jp = JobProspect.create!(
      job: job,
      prospect: @prospect,
      qualification_status: 'qualified'
    )
    OutreachTask.create!(
      job: job,
      job_prospect: jp,
      prepared_message: 'Hi',
      destination_phone: '2348012345678',
      whatsapp_url: 'https://wa.me/2348012345678',
      idempotency_key: SecureRandom.hex(16),
      status: 'sent',
      completed_at: Time.current
    )

    # Job deletion fails because dependent job_prospects has dependent outreach_tasks
    assert_not job.destroy
    assert_raises(ActiveRecord::RecordNotDestroyed) do
      job.destroy!
    end

    # JobProspect deletion is restricted with explicit error
    assert_not jp.destroy
    assert_includes jp.errors[:base], 'Cannot delete record because dependent outreach tasks exist'

    # Foreign key restriction at DB level also protects it against raw SQL delete
    assert_raises(ActiveRecord::StatementInvalid) do
      job.delete
    end
  end

  test '13. tenant ownership: prevents outreach task referencing job different from job_prospect' do
    job1 = Job.create!(user: @user, name: 'Job 1', message_template: 'Hi {{business_name}}')
    job2 = Job.create!(user: @user, name: 'Job 2', message_template: 'Hi {{business_name}}')
    jp1  = JobProspect.create!(job: job1, prospect: @prospect, qualification_status: 'qualified')

    mismatched_task = OutreachTask.new(
      job: job2,
      job_prospect: jp1,
      prepared_message: 'Hi',
      destination_phone: '2348012345678',
      whatsapp_url: 'https://wa.me/2348012345678',
      idempotency_key: SecureRandom.hex(16)
    )
    assert_not mismatched_task.valid?
    assert_includes mismatched_task.errors[:job_prospect], 'must belong to the same Job as the OutreachTask'
  end

  test '14. geographic consistency: rejects target having both catalog city and custom city' do
    job = Job.create!(user: @user, name: 'Geo Job', message_template: 'Hi')
    conflicting_target = JobTarget.new(
      job: job,
      country: @country,
      country_city: @city,
      custom_city_name: 'Custom Lagos Suburb',
      category: 'restaurant'
    )
    assert_not conflicting_target.valid?
    assert_includes conflicting_target.errors[:base], 'A target cannot have both a catalog city and a custom city name'

    # Enforced at DB constraint level
    assert_raises(ActiveRecord::StatementInvalid) do
      conflicting_target.save!(validate: false)
    end
  end

  test '15. geographic consistency: rejects target where city country does not match target country' do
    ghana = Country.find_by!(iso_country_code: 'GH')
    job = Job.create!(user: @user, name: 'Geo Job 2', message_template: 'Hi')

    mismatched_target = JobTarget.new(
      job: job,
      country: ghana, # Ghana
      country_city: @city, # Lagos (Nigeria)
      category: 'restaurant'
    )
    assert_not mismatched_target.valid?
    assert_includes mismatched_target.errors[:country_city], 'must belong to the selected country'
  end

  test '16. device concurrency: prevents device having multiple active tasks in-flight' do
    job = Job.create!(user: @user, name: 'Concurrency Job', message_template: 'Hi')
    jp1 = JobProspect.create!(job: job, prospect: @prospect, qualification_status: 'qualified')

    prospect2 = Prospect.create!(
      user: @user,
      google_place_id: "place_#{SecureRandom.hex(8)}",
      business_name: 'Beta Dental',
      status: 'NEW'
    )
    jp2 = JobProspect.create!(job: job, prospect: prospect2, qualification_status: 'qualified')

    reg = ExtensionDevice.register_device!(user: @user, client_name: 'Solo Extension')
    device = reg[:device]

    task1 = OutreachTask.create!(
      job: job, job_prospect: jp1, prepared_message: 'Hi 1', destination_phone: '2348011111111',
      whatsapp_url: 'https://wa.me/2348011111111', idempotency_key: SecureRandom.hex(16), status: 'queued'
    )
    task2 = OutreachTask.create!(
      job: job, job_prospect: jp2, prepared_message: 'Hi 2', destination_phone: '2348012222222',
      whatsapp_url: 'https://wa.me/2348012222222', idempotency_key: SecureRandom.hex(16), status: 'queued'
    )

    # Claim task 1
    task1.claim_for_device!(device)
    assert_equal 'dispatched', task1.status

    # Claiming task 2 while task 1 is in-flight must raise error
    assert_raises(StandardError) do
      task2.claim_for_device!(device)
    end

    # Complete task 1
    task1.mark_sent!

    # Now task 2 can be claimed
    task2.claim_for_device!(device)
    assert_equal 'dispatched', task2.status
  end

  test '17. state transitions: rejects marking sent from queued or uncertain without dispatch' do
    job = Job.create!(user: @user, name: 'State Transition Job', message_template: 'Hi')
    jp = JobProspect.create!(job: job, prospect: @prospect, qualification_status: 'qualified')
    task = OutreachTask.create!(
      job: job, job_prospect: jp, prepared_message: 'Hi', destination_phone: '2348012345678',
      whatsapp_url: 'https://wa.me/2348012345678', idempotency_key: SecureRandom.hex(16), status: 'queued'
    )

    assert_raises(StandardError) do
      task.mark_sent!
    end

    task.mark_uncertain!(error_details: 'Lost connection')
    assert_raises(StandardError) do
      task.mark_sent!
    end
  end
end

