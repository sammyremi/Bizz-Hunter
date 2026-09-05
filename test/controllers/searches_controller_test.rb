# test/controllers/searches_controller_test.rb

# frozen_string_literal: true

require 'test_helper'

class SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user1 = User.create!(
      name: 'User One',
      email: 'user1@example.com',
      password: 'password123'
    )
    @user2 = User.create!(
      name: 'User Two',
      email: 'user2@example.com',
      password: 'password123'
    )

    @token1 = JsonWebToken.encode(user_id: @user1.id)
    @token2 = JsonWebToken.encode(user_id: @user2.id)

    @headers1 = { 'Authorization' => "Bearer #{@token1}" }
    @headers2 = { 'Authorization' => "Bearer #{@token2}" }
  end

  test 'user1 can view own search history and analysis' do
    search = @user1.searches.create!(
      query: 'Hotels in Lagos',
      business_type: 'Hotel',
      location_name: 'Lagos',
      results_count: 1
    )

    search.search_results.create!(
      user: @user1,
      google_place_id: 'place_hotel_1',
      name: 'Eko Suites',
      business_type: 'Hotel',
      phone: '+2348011111111',
      website: nil,
      opportunity_score: 87,
      opportunity_tier: 'high',
      opportunity_level: 'HIGH'
    )

    # 1. Fetch search history
    get api_v1_searches_url, headers: @headers1
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json['data'].size
    assert_equal 'Hotels in Lagos', json['data'].first['query']

    # 2. Fetch search analysis
    get "/api/v1/searches/#{search.id}/analysis", headers: @headers1
    assert_response :success
    analysis_json = JSON.parse(response.body)
    assert_equal 1, analysis_json['data']['summary']['total_businesses']
    assert_equal 'Eko Suites', analysis_json['data']['top_prospects'].first['name']
  end

  test 'user2 cannot access user1 search analysis (data isolation)' do
    search1 = @user1.searches.create!(
      query: 'Private Search',
      business_type: 'Restaurant',
      location_name: 'Abuja',
      results_count: 1
    )

    get "/api/v1/searches/#{search1.id}/analysis", headers: @headers2
    assert_response :not_found
  end
end
