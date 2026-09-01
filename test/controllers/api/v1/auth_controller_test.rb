# test/controllers/api/v1/auth_controller_test.rb

# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class AuthControllerTest < ActionDispatch::IntegrationTest
      test "registers user and returns JWT token" do
        post api_v1_auth_register_url, params: {
          name: 'Jane Doe',
          email: 'jane@example.com',
          password: 'password123'
        }, as: :json

        assert_response :created
        json = JSON.parse(response.body)
        assert json['success']
        assert_not_nil json['token']
        assert_equal 'Jane Doe', json['user']['name']
      end

      test "authenticates user with valid credentials" do
        User.create!(name: 'Jane Doe', email: 'jane@example.com', password: 'password123')

        post api_v1_auth_login_url, params: {
          email: 'jane@example.com',
          password: 'password123'
        }, as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert json['success']
        assert_not_nil json['token']
      end

      test "rejects invalid login credentials" do
        User.create!(name: 'Jane Doe', email: 'jane@example.com', password: 'password123')

        post api_v1_auth_login_url, params: {
          email: 'jane@example.com',
          password: 'wrongpassword'
        }, as: :json

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_not json['success']
      end

      test "returns profile for authenticated token" do
        user = User.create!(name: 'Jane Doe', email: 'jane@example.com', password: 'password123')
        token = JsonWebToken.encode(user_id: user.id)

        get api_v1_auth_me_url, headers: { 'Authorization' => "Bearer #{token}" }

        assert_response :ok
        json = JSON.parse(response.body)
        assert json['success']
        assert_equal 'jane@example.com', json['user']['email']
      end
    end
  end
end
