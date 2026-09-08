# test/models/search_test.rb

# frozen_string_literal: true

require 'test_helper'

class SearchTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: 'Search Tester',
      email: "search_test_#{SecureRandom.hex(4)}@example.com",
      password: 'password123'
    )

    @profile = @user.prospecting_profiles.create!(
      name: 'Website Dev for Restaurants',
      service: 'Website Development',
      service_description: 'I build websites for restaurants.'
    )
  end

  test "1. search belongs_to prospecting_profile (optional)" do
    search = @user.searches.create!(
      business_type: 'restaurants',
      location_name: 'Abuja',
      query: 'restaurants in Abuja',
      results_count: 10,
      prospecting_profile: @profile
    )
    assert_equal @profile, search.prospecting_profile
  end

  test "2. search without profile is still valid" do
    search = @user.searches.create!(
      business_type: 'hotels',
      location_name: 'Lagos',
      query: 'hotels in Lagos',
      results_count: 5
    )
    assert_nil search.prospecting_profile
    assert search.persisted?
  end

  test "3. prospecting_profile has_many searches" do
    s1 = @user.searches.create!(
      business_type: 'restaurants',
      location_name: 'Abuja',
      query: 'restaurants in Abuja',
      results_count: 3,
      prospecting_profile: @profile
    )
    s2 = @user.searches.create!(
      business_type: 'hotels',
      location_name: 'Lagos',
      query: 'hotels in Lagos',
      results_count: 7,
      prospecting_profile: @profile
    )

    assert_includes @profile.searches, s1
    assert_includes @profile.searches, s2
    assert_equal 2, @profile.searches.count
  end

  test "4. search.prospecting_profile_id is persisted correctly" do
    search = @user.searches.create!(
      business_type: 'cafes',
      location_name: 'Kano',
      query: 'cafes in Kano',
      results_count: 2,
      prospecting_profile: @profile
    )
    search.reload
    assert_equal @profile.id, search.prospecting_profile_id
  end

  test "5. deleting a profile nullifies search relationship (does not delete search)" do
    search = @user.searches.create!(
      business_type: 'restaurants',
      location_name: 'Abuja',
      query: 'restaurants in Abuja',
      results_count: 0,
      prospecting_profile: @profile
    )
    search_id = search.id

    @profile.destroy
    search.reload

    assert_nil search.prospecting_profile_id
    assert Search.find_by(id: search_id).present?, "Search should still exist after profile deletion"
  end

  test "6. search is scoped correctly for user" do
    other_user = User.create!(
      name: 'Other User',
      email: "other_#{SecureRandom.hex(4)}@example.com",
      password: 'password123'
    )

    s_mine = @user.searches.create!(
      business_type: 'restaurants',
      location_name: 'Abuja',
      query: 'restaurants in Abuja',
      results_count: 0
    )
    s_theirs = other_user.searches.create!(
      business_type: 'hotels',
      location_name: 'Lagos',
      query: 'hotels in Lagos',
      results_count: 0
    )

    assert_includes @user.searches, s_mine
    assert_not_includes @user.searches, s_theirs
  end
end
