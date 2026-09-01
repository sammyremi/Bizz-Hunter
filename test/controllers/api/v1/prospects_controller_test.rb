# test/controllers/api/v1/prospects_controller_test.rb

# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ProspectsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user_a = User.create!(name: 'User A', email: 'usera@example.com', password: 'password123')
        @user_b = User.create!(name: 'User B', email: 'userb@example.com', password: 'password123')

        @token_a = JsonWebToken.encode(user_id: @user_a.id)
        @token_b = JsonWebToken.encode(user_id: @user_b.id)

        @prospect_a = @user_a.prospects.create!(
          google_place_id: 'ChIJ_A',
          business_name: 'Business A',
          status: 'NEW'
        )
      end

      test "requires authentication for prospects endpoint" do
        get api_v1_prospects_url
        assert_response :unauthorized
      end

      test "user A can list only their own prospects" do
        @user_b.prospects.create!(google_place_id: 'ChIJ_B', business_name: 'Business B', status: 'NEW')

        get api_v1_prospects_url, headers: { 'Authorization' => "Bearer #{@token_a}" }

        assert_response :ok
        json = JSON.parse(response.body)
        assert json['success']
        assert_equal 1, json['data'].length
        assert_equal 'Business A', json['data'][0]['business_name']
      end

      test "user A can create a prospect" do
        post api_v1_prospects_url, params: {
          google_place_id: 'ChIJ_NEW',
          business_name: 'New Restaurant',
          category: 'restaurant',
          rating: 4.5,
          review_count: 50,
          status: 'NEW'
        }, headers: { 'Authorization' => "Bearer #{@token_a}" }, as: :json

        assert_response :created
        json = JSON.parse(response.body)
        assert json['success']
        assert_equal 'New Restaurant', json['data']['business_name']
      end

      test "user A can update their prospect status and notes" do
        patch api_v1_prospect_url(@prospect_a), params: {
          status: 'CONTACTED',
          notes: 'Called owner on Monday'
        }, headers: { 'Authorization' => "Bearer #{@token_a}" }, as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert_equal 'CONTACTED', json['data']['status']
        assert_equal 'Called owner on Monday', json['data']['notes']
      end

      test "user B CANNOT view or update user A's prospect" do
        patch api_v1_prospect_url(@prospect_a), params: {
          status: 'CONTACTED'
        }, headers: { 'Authorization' => "Bearer #{@token_b}" }, as: :json

        assert_response :not_found

        get api_v1_prospect_url(@prospect_a), headers: { 'Authorization' => "Bearer #{@token_b}" }
        assert_response :not_found
      end

      test "user B CANNOT delete user A's prospect" do
        delete api_v1_prospect_url(@prospect_a), headers: { 'Authorization' => "Bearer #{@token_b}" }
        assert_response :not_found

        assert Prospect.exists?(@prospect_a.id)
      end
    end
  end
end
