# test/controllers/outreach_messages_controller_test.rb

# frozen_string_literal: true

require 'test_helper'

class OutreachMessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @orig_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    @user = User.create!(
      email: 'outreach_ctrl_user@example.com',
      password: 'Password123!',
      name: 'Outreach Controller User'
    )

    @other_user = User.create!(
      email: 'other_outreach_user@example.com',
      password: 'Password123!',
      name: 'Other Outreach User'
    )

    @profile = ProspectingProfile.create!(
      user: @user,
      name: 'Web Dev Profile',
      service: 'Website Development',
      service_description: 'Building modern websites',
      target_businesses: ['Restaurants'],
      opportunity_signals: ['No website'],
      contact_signals: ['Phone available']
    )

    @search = Search.create!(
      user: @user,
      prospecting_profile: @profile,
      business_type: 'restaurants',
      location_name: 'Abuja'
    )

    @search_result = SearchResult.create!(
      search: @search,
      user: @user,
      google_place_id: 'place_abuja_diner',
      name: 'Abuja Diner',
      phone: '+2348030001111'
    )

    @token = JsonWebToken.encode(user_id: @user.id)
    @other_token = JsonWebToken.encode(user_id: @other_user.id)
  end

  teardown do
    Rails.cache = @orig_cache
  end

  test 'POST /api/v1/outreach_messages allows 1 guest message per day and blocks second' do
    business_payload = { name: 'Guest Cafe', phone: '+2348012345678', category: 'Cafe' }
    
    # First attempt: allowed
    post '/api/v1/outreach_messages', params: { business: business_payload }
    assert_response :ok
    json = JSON.parse(response.body)
    assert json['success']
    assert_not_nil json['data']['whatsapp_url']

    # Second attempt: blocked
    post '/api/v1/outreach_messages', params: { business: business_payload }
    assert_response :too_many_requests
    json2 = JSON.parse(response.body)
    refute json2['success']
    assert_equal 'GUEST_LIMIT_REACHED', json2['code']
  end

  test 'POST /api/v1/outreach_messages generates message for owned search result' do
    post '/api/v1/outreach_messages',
         params: { search_result_id: @search_result.id },
         headers: { 'Authorization' => "Bearer #{@token}" }

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']
    assert_not_nil json['data']['whatsapp_url']
    assert_includes json['data']['whatsapp_url'], 'wa.me/2348030001111'
  end

  test 'POST /api/v1/outreach_messages returns 404 for unowned search result' do
    post '/api/v1/outreach_messages',
         params: { search_result_id: @search_result.id },
         headers: { 'Authorization' => "Bearer #{@other_token}" }

    assert_response :not_found
    json = JSON.parse(response.body)
    refute json['success']
  end
end
