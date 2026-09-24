# test/controllers/api/v1/prospect_briefs_controller_test.rb

# frozen_string_literal: true

require 'test_helper'

class Api::V1::ProspectBriefsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @orig_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    @user = User.create!(
      email: 'brief_ctrl_user@example.com',
      password: 'password123',
      name: 'Brief Controller User'
    )

    @other_user = User.create!(
      email: 'other_brief_user@example.com',
      password: 'password123',
      name: 'Other User'
    )

    @profile = ProspectingProfile.create!(
      user: @user,
      name: 'Web Dev Profile',
      service: 'Website Development',
      service_description: 'Building modern websites for local business growth',
      is_default: true
    )

    @search = Search.create!(
      user: @user,
      business_type: 'restaurant',
      location_name: 'Abuja',
      prospecting_profile: @profile,
      results_count: 1
    )

    @search_result = SearchResult.create!(
      search: @search,
      user: @user,
      name: 'Puzzo Restaurant',
      google_place_id: 'place_puzzo_123',
      phone: '+2348011112222',
      opportunity_score: 92,
      opportunity_tier: 'high'
    )

    @token = JsonWebToken.encode(user_id: @user.id)
    @other_token = JsonWebToken.encode(user_id: @other_user.id)
  end

  teardown do
    Rails.cache = @orig_cache
  end

  test 'unauthenticated user can generate 1 AI prospect brief per day but is blocked on second' do
    business_payload = { name: 'Guest Diner', address: '123 Main St', rating: 4.5 }
    
    # First attempt: allowed
    post api_v1_prospect_briefs_url, params: { business: business_payload }
    assert_response :ok
    json = JSON.parse(response.body)
    assert json['success']
    assert_equal 'Guest Diner', json['data']['business_name']

    # Second attempt: blocked by daily limit (429 Too Many Requests)
    post api_v1_prospect_briefs_url, params: { business: business_payload }
    assert_response :too_many_requests
    json2 = JSON.parse(response.body)
    assert_equal false, json2['success']
    assert_equal 'GUEST_LIMIT_REACHED', json2['code']
  end

  test 'authenticated user can generate prospect brief for their search result' do
    post api_v1_prospect_briefs_url,
         params: { search_result_id: @search_result.id },
         headers: { 'Authorization' => "Bearer #{@token}" }

    assert_response :ok
    json = JSON.parse(response.body)

    assert json['success']
    assert_equal 'Puzzo Restaurant', json['data']['business_name']
    assert_equal 92, json['data']['opportunity_score']
    assert_not_nil json['data']['summary']
    assert_not_nil json['data']['why_this_is_a_prospect']
  end

  test 'prospect brief uses the prospecting profile from the search, not an arbitrary user profile' do
    # Create a second profile on the same user. If the controller were broken,
    # it might grab this one via .recent or .first. The brief must use @profile,
    # which is the one attached to @search.
    _other_profile = ProspectingProfile.create!(
      user: @user,
      name: 'Car Sales Profile',
      service: 'Car Sales',
      service_description: 'Selling cars to logistics fleets',
      is_default: false
    )

    post api_v1_prospect_briefs_url,
         params: { search_result_id: @search_result.id },
         headers: { 'Authorization' => "Bearer #{@token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json['success']
    # The profile name in the brief must come from @profile (the search's profile),
    # not from the newly created Car Sales profile.
    assert_equal 'Web Dev Profile', json['data']['prospecting_profile_name']
  end

  test 'returns 422 when search result has no prospecting profile associated' do
    # Create a search explicitly WITHOUT a prospecting profile
    search_no_profile = Search.create!(
      user: @user,
      business_type: 'hotel',
      location_name: 'Lagos',
      prospecting_profile: nil,
      results_count: 1
    )
    result_no_profile = SearchResult.create!(
      search: search_no_profile,
      user: @user,
      name: 'Lagos Hotel',
      google_place_id: 'place_lagos_hotel_456',
      phone: '+2348099998888',
      opportunity_score: 50,
      opportunity_tier: 'medium'
    )

    post api_v1_prospect_briefs_url,
         params: { search_result_id: result_no_profile.id },
         headers: { 'Authorization' => "Bearer #{@token}" }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json['success']
    assert_includes json['message'].downcase, 'prospecting profile'
  end

  test 'user cannot generate prospect brief for another user search result' do
    post api_v1_prospect_briefs_url,
         params: { search_result_id: @search_result.id },
         headers: { 'Authorization' => "Bearer #{@other_token}" }

    assert_response :not_found
  end

  test 'multi-profile test: Search A uses Profile A and Search B uses Profile B regardless of default' do
    profile_b = ProspectingProfile.create!(
      user: @user,
      name: 'Car Sales Profile',
      service: 'Car Sales',
      service_description: 'Selling cars to logistics fleets',
      is_default: true
    )

    search_b = Search.create!(
      user: @user,
      business_type: 'logistics',
      location_name: 'Kano',
      prospecting_profile: profile_b,
      results_count: 1
    )

    result_b = SearchResult.create!(
      search: search_b,
      user: @user,
      name: 'Kano Logistics',
      google_place_id: 'place_kano_logistics',
      phone: '+2348033334444',
      opportunity_score: 85,
      opportunity_tier: 'high'
    )

    # Search A must return Profile A ('Web Dev Profile')
    post api_v1_prospect_briefs_url,
         params: { search_result_id: @search_result.id },
         headers: { 'Authorization' => "Bearer #{@token}" }
    assert_response :ok
    json_a = JSON.parse(response.body)
    assert_equal 'Web Dev Profile', json_a['data']['prospecting_profile_name']

    # Search B must return Profile B ('Car Sales Profile')
    post api_v1_prospect_briefs_url,
         params: { search_result_id: result_b.id },
         headers: { 'Authorization' => "Bearer #{@token}" }
    assert_response :ok
    json_b = JSON.parse(response.body)
    assert_equal 'Car Sales Profile', json_b['data']['prospecting_profile_name']
  end

  test 'saved prospect can generate brief and correctly resolves profile via associated search' do
    prospect = Prospect.create!(
      user: @user,
      business_name: 'Puzzo Restaurant',
      google_place_id: 'place_puzzo_123',
      phone_number: '+2348011112222',
      status: 'NEW'
    )

    post api_v1_prospect_briefs_url,
         params: { prospect_id: prospect.id, google_place_id: prospect.google_place_id },
         headers: { 'Authorization' => "Bearer #{@token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json['success']
    assert_equal 'Puzzo Restaurant', json['data']['business_name']
    assert_equal 'Web Dev Profile', json['data']['prospecting_profile_name']
  end

  test 'user cannot generate brief for another user saved prospect' do
    other_prospect = Prospect.create!(
      user: @other_user,
      business_name: 'Secret Business',
      google_place_id: 'place_secret_999',
      status: 'NEW'
    )

    post api_v1_prospect_briefs_url,
         params: { prospect_id: other_prospect.id },
         headers: { 'Authorization' => "Bearer #{@token}" }

    assert_response :not_found
  end
end
