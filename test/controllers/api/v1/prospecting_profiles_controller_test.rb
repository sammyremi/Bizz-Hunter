# test/controllers/api/v1/prospecting_profiles_controller_test.rb

# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ProspectingProfilesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user_a = User.create!(name: 'User A', email: 'user_a@example.com', password: 'password123')
        @user_b = User.create!(name: 'User B', email: 'user_b@example.com', password: 'password123')

        @token_a = JsonWebToken.encode(user_id: @user_a.id)
        @token_b = JsonWebToken.encode(user_id: @user_b.id)

        @profile_a = @user_a.prospecting_profiles.create!(
          name: 'Restaurant Web Dev',
          service: 'Website Development',
          service_description: 'I build modern websites for local restaurants.',
          target_businesses: ['restaurants', 'cafes'],
          opportunity_signals: ['no_website'],
          contact_signals: ['phone_available'],
          is_default: true
        )
      end

      # --- AUTHENTICATION TESTS ---
      test "requires authentication for all prospecting profiles endpoints" do
        get api_v1_prospecting_profiles_url
        assert_response :unauthorized

        get api_v1_prospecting_profile_url(@profile_a)
        assert_response :unauthorized

        post api_v1_prospecting_profiles_url, params: { name: 'Test' }, as: :json
        assert_response :unauthorized

        patch api_v1_prospecting_profile_url(@profile_a), params: { name: 'Test' }, as: :json
        assert_response :unauthorized

        delete api_v1_prospecting_profile_url(@profile_a)
        assert_response :unauthorized
      end

      # --- INDEX TESTS ---
      test "user A receives only their own profiles" do
        @user_b.prospecting_profiles.create!(
          name: 'Hotel SEO',
          service: 'SEO',
          service_description: 'SEO for hotels.'
        )

        get api_v1_prospecting_profiles_url, headers: { 'Authorization' => "Bearer #{@token_a}" }

        assert_response :ok
        json = JSON.parse(response.body)
        assert json['success']
        assert_equal 1, json['data'].length
        assert_equal 'Restaurant Web Dev', json['data'][0]['name']
        assert_equal @user_a.id, json['data'][0]['user_id']
      end

      # --- SHOW TESTS ---
      test "user A can retrieve their own profile" do
        get api_v1_prospecting_profile_url(@profile_a), headers: { 'Authorization' => "Bearer #{@token_a}" }

        assert_response :ok
        json = JSON.parse(response.body)
        assert json['success']
        assert_equal 'Restaurant Web Dev', json['data']['name']
        assert_equal ['restaurants', 'cafes'], json['data']['target_businesses']
      end

      test "user B CANNOT retrieve user A's profile" do
        get api_v1_prospecting_profile_url(@profile_a), headers: { 'Authorization' => "Bearer #{@token_b}" }

        assert_response :not_found
        json = JSON.parse(response.body)
        assert_not json['success']
        assert_equal 'Prospecting profile not found', json['message']
      end

      test "returns 404 for nonexistent profile" do
        get api_v1_prospecting_profile_url(id: SecureRandom.uuid), headers: { 'Authorization' => "Bearer #{@token_a}" }

        assert_response :not_found
      end

      # --- CREATE TESTS ---
      test "user A can create a valid profile" do
        post api_v1_prospecting_profiles_url, params: {
          name: 'E-commerce for Fashion',
          service: 'E-commerce Development',
          service_description: 'Building Shopify stores for local boutiques.',
          target_businesses: ['boutiques', 'fashion_stores'],
          opportunity_signals: ['no_website', 'low_rating'],
          contact_signals: ['whatsapp_available'],
          is_default: false
        }, headers: { 'Authorization' => "Bearer #{@token_a}" }, as: :json

        assert_response :created
        json = JSON.parse(response.body)
        assert json['success']
        assert_equal 'E-commerce for Fashion', json['data']['name']
        assert_equal @user_a.id, json['data']['user_id']
      end

      test "cannot assign another user_id on create" do
        post api_v1_prospecting_profiles_url, params: {
          user_id: @user_b.id,
          name: 'Hacked Profile',
          service: 'Hacker Service',
          service_description: 'Attempting to inject user_id.'
        }, headers: { 'Authorization' => "Bearer #{@token_a}" }, as: :json

        assert_response :created
        json = JSON.parse(response.body)
        assert_equal @user_a.id, json['data']['user_id'], "user_id must always be current_user.id"
      end

      test "returns validation errors for invalid profile creation" do
        post api_v1_prospecting_profiles_url, params: {
          name: '',
          service: '',
          service_description: ''
        }, headers: { 'Authorization' => "Bearer #{@token_a}" }, as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_not json['success']
        assert_equal 'Validation failed', json['message']
        assert_includes json['errors']['name'], "can't be blank"
      end

      # --- UPDATE TESTS ---
      test "user A can update their own profile" do
        patch api_v1_prospecting_profile_url(@profile_a), params: {
          name: 'Updated Restaurant Web Dev',
          is_default: true
        }, headers: { 'Authorization' => "Bearer #{@token_a}" }, as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert json['success']
        assert_equal 'Updated Restaurant Web Dev', json['data']['name']
      end

      test "user B CANNOT update user A's profile" do
        patch api_v1_prospecting_profile_url(@profile_a), params: {
          name: 'Malicious Update'
        }, headers: { 'Authorization' => "Bearer #{@token_b}" }, as: :json

        assert_response :not_found
        assert_equal 'Restaurant Web Dev', @profile_a.reload.name
      end

      test "returns validation errors on invalid update" do
        patch api_v1_prospecting_profile_url(@profile_a), params: {
          name: ''
        }, headers: { 'Authorization' => "Bearer #{@token_a}" }, as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_not json['success']
      end

      # --- DELETE TESTS ---
      test "user A can delete their own profile" do
        delete api_v1_prospecting_profile_url(@profile_a), headers: { 'Authorization' => "Bearer #{@token_a}" }

        assert_response :ok
        assert_not ProspectingProfile.exists?(@profile_a.id)
      end

      test "user B CANNOT delete user A's profile" do
        delete api_v1_prospecting_profile_url(@profile_a), headers: { 'Authorization' => "Bearer #{@token_b}" }

        assert_response :not_found
        assert ProspectingProfile.exists?(@profile_a.id)
      end
    end
  end
end
