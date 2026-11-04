# frozen_string_literal: true

require 'test_helper'

class JobsManagementAndTargetsTest < ActionDispatch::IntegrationTest
  def setup
    load Rails.root.join('db', 'seeds', 'jobs_geographic_catalog.rb')

    @user = User.create!(
      name: 'Job Manager',
      email: "manager_#{SecureRandom.hex(4)}@example.com",
      password: 'StrongPassword123!'
    )
    @other_user = User.create!(
      name: 'Other Manager',
      email: "other_mgr_#{SecureRandom.hex(4)}@example.com",
      password: 'StrongPassword123!'
    )

    @user_token = JsonWebToken.encode(user_id: @user.id)
    @other_token = JsonWebToken.encode(user_id: @other_user.id)

    @user_auth_headers = { 'Authorization' => "Bearer #{@user_token}" }
    @other_auth_headers = { 'Authorization' => "Bearer #{@other_token}" }

    @profile = ProspectingProfile.create!(
      user: @user,
      name: 'Websites for Clinics',
      service: 'Web Development',
      service_description: 'Modern clinic websites'
    )
    @other_profile = ProspectingProfile.create!(
      user: @other_user,
      name: 'Foreign Profile',
      service: 'SEO',
      service_description: 'SEO work'
    )

    @country_ng = Country.find_by!(iso_country_code: 'NG')
    @country_gh = Country.find_by!(iso_country_code: 'GH')
  end

  # 1. Countries lookup
  test 'GET /api/v1/countries lists active launch countries' do
    get '/api/v1/countries', headers: @user_auth_headers
    assert_response :ok
    json = JSON.parse(response.body)
    assert json['success']
    assert_equal 10, json['data'].size
  end

  # 2. Cities lookup for a country
  test 'GET /api/v1/countries/:id/cities returns default pool cities' do
    get "/api/v1/countries/#{@country_ng.iso_country_code}/cities", headers: @user_auth_headers
    assert_response :ok
    json = JSON.parse(response.body)
    assert json['success']
    assert_equal 20, json['data'].size
    assert_equal 'Nigeria', json['country']['name']
  end

  # 3. Create a Job with automatic city pool expansion
  test 'POST /api/v1/jobs creates a job and expands automatic city pool' do
    post '/api/v1/jobs', headers: @user_auth_headers, params: {
      job: {
        name: 'Auto Clinics Job',
        prospecting_profile_id: @profile.id,
        website_targeting: 'both',
        daily_discovery_target: 80,
        daily_outreach_target: 20,
        outreach_mode: 'manual_review',
        message_template: 'Hello {{business_name}}, we can build your site!'
      },
      target_generation: {
        countries: ['NG'],
        categories: ['dental clinic', 'hospital'],
        city_mode: 'automatic'
      }
    }

    assert_response :created
    json = JSON.parse(response.body)
    assert json['success']
    assert_equal 'Auto Clinics Job', json['data']['name']
    assert_equal 40, json['data']['target_counts']['total'] # 20 cities * 2 categories = 40 targets

    job = Job.find(json['data']['id'])
    assert_equal 40, job.job_targets.count
    assert_equal 40, job.job_targets.active.count
  end

  # 4. Multi-country and multi-category expansion
  test 'POST /api/v1/jobs supports multiple countries and categories' do
    post '/api/v1/jobs', headers: @user_auth_headers, params: {
      job: {
        name: 'Multi-Country Job',
        message_template: 'Hi {{business_name}}'
      },
      target_generation: {
        countries: ['NG', 'GH'],
        categories: ['hotel', 'resort'],
        city_mode: 'automatic'
      }
    }

    assert_response :created
    json = JSON.parse(response.body)
    assert json['success']
    # 20 NG cities + 20 GH cities = 40 cities * 2 categories = 80 targets
    assert_equal 80, json['data']['target_counts']['total']
  end

  # 5. Manual city selection and custom cities
  test 'POST /api/v1/jobs supports manual city selection and custom cities' do
    lagos = @country_ng.country_cities.find_by!(name: 'Lagos')
    abuja = @country_ng.country_cities.find_by!(name: 'Abuja')

    post '/api/v1/jobs', headers: @user_auth_headers, params: {
      job: {
        name: 'Manual Cities Job',
        message_template: 'Hi {{business_name}}'
      },
      target_generation: {
        countries: ['NG'],
        categories: ['restaurant'],
        city_mode: 'manual',
        city_ids: [lagos.id, abuja.id],
        custom_cities: [
          { name: 'Victoria Island District', state_or_region: 'Lagos State' }
        ]
      }
    }

    assert_response :created
    json = JSON.parse(response.body)
    assert json['success']
    # 2 catalog cities + 1 custom city = 3 targets
    assert_equal 3, json['data']['target_counts']['total']

    job = Job.find(json['data']['id'])
    assert_equal 1, job.job_targets.where.not(custom_city_name: nil).count
  end

  # 6. Per-Job city exclusions in automatic pool
  test 'POST /api/v1/jobs supports excluding individual cities for a Job without affecting global catalog' do
    lagos = @country_ng.country_cities.find_by!(name: 'Lagos')
    kano  = @country_ng.country_cities.find_by!(name: 'Kano')

    post '/api/v1/jobs', headers: @user_auth_headers, params: {
      job: {
        name: 'Excluded Cities Job',
        message_template: 'Hi {{business_name}}'
      },
      target_generation: {
        countries: ['NG'],
        categories: ['gym'],
        city_mode: 'automatic',
        excluded_city_ids: [lagos.id, kano.id]
      }
    }

    assert_response :created
    json = JSON.parse(response.body)
    # 20 default cities - 2 excluded = 18 cities * 1 category = 18 targets
    assert_equal 18, json['data']['target_counts']['total']

    # Verify global Lagos and Kano records remain active!
    assert lagos.reload.is_active
    assert kano.reload.is_active
  end

  # 7. Rejecting foreign user's prospecting profile
  test 'POST /api/v1/jobs rejects association with another user profile' do
    post '/api/v1/jobs', headers: @user_auth_headers, params: {
      job: {
        name: 'Theft Job',
        prospecting_profile_id: @other_profile.id,
        message_template: 'Hi {{business_name}}'
      }
    }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json['success']
    assert_includes json['message'], 'must belong to the same user'
  end

  # 8. User ownership isolation on GET /api/v1/jobs
  test 'GET /api/v1/jobs lists only the authenticated user jobs' do
    Job.create!(user: @user, name: 'User 1 Job', message_template: 'Hi')
    Job.create!(user: @other_user, name: 'User 2 Job', message_template: 'Hi')

    get '/api/v1/jobs', headers: @user_auth_headers
    assert_response :ok
    json = JSON.parse(response.body)
    assert json['success']
    assert_equal 1, json['data'].size
    assert_equal 'User 1 Job', json['data'].first['name']
  end

  # 9. Rejecting access to another user's Job
  test 'GET /api/v1/jobs/:id returns 404 when requesting another user job' do
    other_job = Job.create!(user: @other_user, name: 'Secret Job', message_template: 'Hi')

    get "/api/v1/jobs/#{other_job.id}", headers: @user_auth_headers
    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal false, json['success']
    assert_equal 'Job not found', json['message']
  end

  # 10. Preserves target progress across configuration updates
  test 'PATCH /api/v1/jobs/:id preserves target search_count and stats' do
    job = Job.create!(user: @user, name: 'Progress Job', message_template: 'Hi')
    lagos = @country_ng.country_cities.find_by!(name: 'Lagos')

    target = job.job_targets.create!(
      country: @country_ng,
      country_city: lagos,
      category: 'dentist',
      search_count: 5,
      total_discovered_count: 42,
      last_searched_at: 1.day.ago
    )

    patch "/api/v1/jobs/#{job.id}", headers: @user_auth_headers, params: {
      job: { name: 'Renamed Progress Job' },
      target_generation: {
        countries: ['NG'],
        categories: ['dentist', 'optician'],
        city_mode: 'manual',
        city_ids: [lagos.id]
      }
    }

    assert_response :ok
    target.reload
    assert_equal 5, target.search_count
    assert_equal 42, target.total_discovered_count
    assert_not_nil target.last_searched_at
    assert_equal 2, job.job_targets.count # Dentist + Optician
  end

  # 11. State transitions: pause, resume, archive
  test 'POST /api/v1/jobs/:id/pause, resume, and archive workflows' do
    job = Job.create!(user: @user, name: 'State Flow Job', message_template: 'Hi', status: 'draft')
    job.job_targets.create!(country: @country_ng, custom_city_name: 'Test Town', category: 'cafe')

    # Resume (activates)
    post "/api/v1/jobs/#{job.id}/resume", headers: @user_auth_headers
    assert_response :ok
    assert_equal 'active', job.reload.status

    # Pause
    post "/api/v1/jobs/#{job.id}/pause", headers: @user_auth_headers
    assert_response :ok
    assert_equal 'paused', job.reload.status

    # Archive
    post "/api/v1/jobs/#{job.id}/archive", headers: @user_auth_headers
    assert_response :ok
    assert_equal 'archived', job.reload.status
    assert job.reload.archived?

    # Archived job cannot resume
    post "/api/v1/jobs/#{job.id}/resume", headers: @user_auth_headers
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_includes json['message'], 'Cannot resume an archived Job'
  end

  # 12. Transaction rollback if target generation fails
  test 'POST /api/v1/jobs rolls back Job creation if target generation encounters error' do
    assert_no_difference('Job.count') do
      post '/api/v1/jobs', headers: @user_auth_headers, params: {
        job: {
          name: 'Rollback Job',
          message_template: 'Hi'
        },
        target_generation: {
          countries: ['XX_NONEXISTENT'],
          categories: ['bar']
        }
      }
      assert_response :unprocessable_entity
    end
  end
end

