# test/controllers/api/v1/business_discovery_controller_test.rb

# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class BusinessDiscoveryControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(
          name: 'Discovery Tester',
          email: "discovery_#{SecureRandom.hex(4)}@example.com",
          password: 'password123'
        )
        @other_user = User.create!(
          name: 'Other User',
          email: "other_discovery_#{SecureRandom.hex(4)}@example.com",
          password: 'password123'
        )

        @token = JsonWebToken.encode(user_id: @user.id)
        @auth_headers = { 'Authorization' => "Bearer #{@token}" }

        @profile = @user.prospecting_profiles.create!(
          name: 'Website Dev for Restaurants',
          service: 'Website Development',
          service_description: 'I build websites for restaurants.'
        )

        @other_profile = @other_user.prospecting_profiles.create!(
          name: "Other User's Profile",
          service: 'SEO',
          service_description: "Other user's SEO service."
        )
      end

      # ------------------------------------------------------------------
      # Profile ownership validation tests
      # ------------------------------------------------------------------

      test "search with valid owned profile_id is accepted and search is linked" do
        mock_results = [
          { id: 'place_001', name: 'Test Restaurant', types: ['restaurant'],
            address: '1 Test St', rating: 4.2, review_count: 50,
            phone: '+2348011111111', national_phone: '0801 111 1111',
            website: nil, google_maps_url: 'https://maps.google.com/?cid=1',
            latitude: 6.5, longitude: 3.3 }
        ]

        with_stub(GooglePlaces::BusinessDiscovery, :call, mock_results) do
          get '/api/v1/business-discovery/search',
              params: {
                business_type: 'restaurants',
                location_name: 'Lagos',
                prospecting_profile_id: @profile.id
              },
              headers: @auth_headers

          assert_response :success
          json = JSON.parse(response.body)
          assert json['success']

          # Profile summary should be in response
          assert_not_nil json['prospecting_profile']
          assert_equal @profile.id, json['prospecting_profile']['id']
          assert_equal @profile.name, json['prospecting_profile']['name']
          assert_equal @profile.service, json['prospecting_profile']['service']

          # Search record should be linked to the profile
          assert_not_nil json['search_id']
          saved_search = Search.find(json['search_id'])
          assert_equal @profile.id, saved_search.prospecting_profile_id
        end
      end

      test "search with another user's profile_id is rejected (IDOR protection)" do
        get '/api/v1/business-discovery/search',
            params: {
              business_type: 'restaurants',
              location_name: 'Lagos',
              prospecting_profile_id: @other_profile.id
            },
            headers: @auth_headers

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal false, json['success']
        assert_match /not found/i, json['message']
      end

      test "search with non-existent profile_id is rejected" do
        fake_id = SecureRandom.uuid
        get '/api/v1/business-discovery/search',
            params: {
              business_type: 'restaurants',
              location_name: 'Lagos',
              prospecting_profile_id: fake_id
            },
            headers: @auth_headers

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_equal false, json['success']
      end

      test "search without profile_id preserves existing behavior" do
        mock_results = [
          { id: 'place_002', name: 'Plain Hotel', types: ['hotel'],
            address: '2 Hotel Rd', rating: 3.8, review_count: 20,
            phone: nil, national_phone: nil,
            website: 'https://hotel.com', google_maps_url: 'https://maps.google.com/?cid=2',
            latitude: 6.5, longitude: 3.3 }
        ]

        with_stub(GooglePlaces::BusinessDiscovery, :call, mock_results) do
          get '/api/v1/business-discovery/search',
              params: { business_type: 'hotels', location_name: 'Abuja' },
              headers: @auth_headers

          assert_response :success
          json = JSON.parse(response.body)
          assert json['success']
          assert_nil json['prospecting_profile']

          assert_not_nil json['search_id']
          saved_search = Search.find(json['search_id'])
          assert_nil saved_search.prospecting_profile_id
        end
      end

      test "search without profile works for unauthenticated (guest) user" do
        mock_results = []

        with_stub(GooglePlaces::BusinessDiscovery, :call, mock_results) do
          get '/api/v1/business-discovery/search',
              params: { business_type: 'cafes', location_name: 'Kano' }

          # Should not return unauthorized — guest search is allowed (quota permitting)
          assert_not_equal 401, response.status
        end
      end

      test "search with profile_id but no auth returns unauthorized" do
        get '/api/v1/business-discovery/search',
            params: {
              business_type: 'restaurants',
              location_name: 'Lagos',
              prospecting_profile_id: @profile.id
            }

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal false, json['success']
      end

      # ------------------------------------------------------------------
      # Persistence tests
      # ------------------------------------------------------------------

      test "search_persistence correctly stores prospecting_profile_id" do
        profile2 = @user.prospecting_profiles.create!(
          name: 'Hotel Dev',
          service: 'Website Development',
          service_description: 'Websites for hotels.'
        )

        mock_results = []

        with_stub(GooglePlaces::BusinessDiscovery, :call, mock_results) do
          get '/api/v1/business-discovery/search',
              params: {
                business_type: 'hotels',
                location_name: 'Port Harcourt',
                prospecting_profile_id: profile2.id
              },
              headers: @auth_headers

          assert_response :success
          json = JSON.parse(response.body)
          search = Search.find(json['search_id'])
          assert_equal profile2.id, search.prospecting_profile_id
        end
      end
    end
  end
end
