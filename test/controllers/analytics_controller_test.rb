# test/controllers/analytics_controller_test.rb

# frozen_string_literal: true

require 'test_helper'

class AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: 'Samuel Adebayo',
      email: 'samuel@example.com',
      password: 'password123'
    )
    @token = JsonWebToken.encode(user_id: @user.id)
    @headers = { 'Authorization' => "Bearer #{@token}" }
  end

  test 'returns unauthorized when unauthenticated' do
    get api_v1_analytics_url
    assert_response :unauthorized
  end

  test 'returns database analytics for authenticated user' do
    search = @user.searches.create!(
      query: 'Restaurants in Abuja',
      business_type: 'Restaurant',
      location_name: 'Abuja',
      results_count: 2
    )

    search.search_results.create!(
      user: @user,
      google_place_id: 'place_1',
      name: 'Alpha Cafe',
      business_type: 'Restaurant',
      phone: '+2348032079169',
      website: nil,
      opportunity_score: 87,
      opportunity_tier: 'high',
      opportunity_level: 'HIGH'
    )

    search.search_results.create!(
      user: @user,
      google_place_id: 'place_2',
      name: 'Beta Diner',
      business_type: 'Restaurant',
      phone: nil,
      website: 'https://beta.com',
      opportunity_score: 20,
      opportunity_tier: 'low',
      opportunity_level: 'LOW'
    )

    get api_v1_analytics_url, headers: @headers

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']
    assert_equal 2, json['data']['businesses_found']
    assert_equal 1, json['data']['high_opportunity']
    assert_equal 1, json['data']['low_opportunity']
    assert_equal 1, json['data']['no_website']
    assert_equal 1, json['data']['phone_available']
    assert_equal 1, json['data']['total_searches']
  end
end
