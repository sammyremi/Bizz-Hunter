# test/services/user_analytics_test.rb

# frozen_string_literal: true

require 'test_helper'

class UserAnalyticsTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: 'analytics_test_user@example.com',
      password: 'Password123!',
      name: 'Analytics Tester'
    )

    @profile = ProspectingProfile.create!(
      user: @user,
      name: 'Website Dev Profile',
      service: 'Website Development',
      service_description: 'I build modern web applications for local businesses',
      target_businesses: ['Restaurants'],
      opportunity_signals: ['No website'],
      contact_signals: ['Phone available']
    )

    @search = Search.create!(
      user: @user,
      prospecting_profile: @profile,
      business_type: 'restaurants',
      location_name: 'Abuja',
      query: 'restaurants in Abuja',
      results_count: 2
    )

    @res1 = SearchResult.create!(
      search: @search,
      user: @user,
      google_place_id: 'place_1',
      name: 'High Opp Restaurant',
      business_type: 'restaurants',
      types: ['restaurant', 'food'],
      website: nil,
      phone: '+2348011111111',
      rating: 4.8,
      review_count: 300,
      opportunity_score: 90,
      opportunity_tier: 'high',
      opportunity_level: 'HIGH',
      opportunity_factors: ['Matches target', 'No website']
    )

    @res2 = SearchResult.create!(
      search: @search,
      user: @user,
      google_place_id: 'place_2',
      name: 'Med Opp Restaurant',
      business_type: 'restaurants',
      types: ['restaurant'],
      website: 'https://example.com',
      phone: '+2348022222222',
      rating: 4.0,
      review_count: 50,
      opportunity_score: 60,
      opportunity_tier: 'medium',
      opportunity_level: 'MEDIUM',
      opportunity_factors: ['Matches target']
    )

    @prospect = Prospect.create!(
      user: @user,
      google_place_id: 'place_1',
      business_name: 'High Opp Restaurant',
      category: 'restaurant',
      status: 'NEW'
    )
  end

  test 'user_analytics: calculates correct totals, high opp count, and high opp rate' do
    analytics = Analytics::UserAnalytics.call(user: @user)

    assert_equal 2, analytics[:businesses_found]
    assert_equal 1, analytics[:total_searches]
    assert_equal 1, analytics[:saved_prospects]

    assert_equal 1, analytics[:high_opportunity]
    assert_equal 1, analytics[:medium_opportunity]
    assert_equal 0, analytics[:low_opportunity]
    assert_equal 50.0, analytics[:high_opportunity_rate]

    assert_equal 1, analytics[:no_website]
    assert_equal 1, analytics[:website_available]
    assert_equal 2, analytics[:phone_available]
  end

  test 'user_analytics: returns empty state payload for user with no searches' do
    new_user = User.create!(
      email: 'empty_user@example.com',
      password: 'Password123!',
      name: 'Empty User'
    )

    analytics = Analytics::UserAnalytics.call(user: new_user)

    assert_equal 0, analytics[:businesses_found]
    assert_equal 0, analytics[:total_searches]
    assert_equal 0, analytics[:saved_prospects]
    assert_equal 0.0, analytics[:high_opportunity_rate]
    assert_empty analytics[:top_business_types]
    assert_empty analytics[:best_performing_targets]
    assert_empty analytics[:profiles]
    assert_empty analytics[:discovery_trend]
  end

  test 'user_analytics: computes profile performance breakdown accurately' do
    analytics = Analytics::UserAnalytics.call(user: @user)

    assert_equal 1, analytics[:profiles].size
    prof = analytics[:profiles].first

    assert_equal @profile.id, prof[:id]
    assert_equal 'Website Dev Profile', prof[:name]
    assert_equal 1, prof[:searches_count]
    assert_equal 2, prof[:businesses_found]
    assert_equal 1, prof[:high_opportunity_count]
    assert_equal 50.0, prof[:high_opportunity_rate]
  end

  test 'user_analytics: calculates best performing target business types by average score' do
    analytics = Analytics::UserAnalytics.call(user: @user)

    assert_not_empty analytics[:best_performing_targets]
    top_target = analytics[:best_performing_targets].first

    assert_equal 'Food', top_target['type']
    assert_equal 90.0, top_target['avg_score']
    assert_equal 1, top_target['count']
  end

  test 'user_analytics: isolated between users' do
    other_user = User.create!(
      email: 'other_user@example.com',
      password: 'Password123!',
      name: 'Other User'
    )

    analytics = Analytics::UserAnalytics.call(user: other_user)
    assert_equal 0, analytics[:businesses_found]
  end
end
