# test/controllers/api/v1/auth_security_controller_test.rb

# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class AuthSecurityControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(
          name: 'Security User',
          email: 'sec_test@example.com',
          password: 'Password123'
        )
        @token = JsonWebToken.encode(user_id: @user.id)
      end

      test 'POST /api/v1/auth/verify_email verifies user with valid token' do
        raw_token = @user.generate_verification_token!

        post '/api/v1/auth/verify_email', params: { token: raw_token }, as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert json['success']
        assert json['user']['verified']

        @user.reload
        assert @user.verified?
      end

      test 'POST /api/v1/auth/resend_verification sends new verification email for unverified user' do
        @user.update_columns(verified_at: nil, verification_sent_at: nil)

        post '/api/v1/auth/resend_verification', headers: { 'Authorization' => "Bearer #{@token}" }, as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert json['success']
        assert_includes json['message'], 'Verification email sent'
      end

      test 'POST /api/v1/auth/forgot_password returns generic message for any email' do
        post '/api/v1/auth/forgot_password', params: { email: 'sec_test@example.com' }, as: :json
        assert_response :ok
        json = JSON.parse(response.body)
        assert json['success']
        assert_includes json['message'], 'If an account exists'

        post '/api/v1/auth/forgot_password', params: { email: 'unknown@example.com' }, as: :json
        assert_response :ok
        json2 = JSON.parse(response.body)
        assert json2['success']
        assert_equal json['message'], json2['message']
      end

      test 'POST /api/v1/auth/reset_password resets password and invalidates token' do
        raw_token = @user.generate_reset_password_token!

        post '/api/v1/auth/reset_password', params: {
          token: raw_token,
          password: 'NewSecurePassword123'
        }, as: :json

        assert_response :ok
        json = JSON.parse(response.body)
        assert json['success']

        @user.reload
        assert @user.authenticate('NewSecurePassword123')

        # Re-using the same token fails
        post '/api/v1/auth/reset_password', params: {
          token: raw_token,
          password: 'AnotherPassword123'
        }, as: :json

        assert_response :unprocessable_entity
      end

      test 'POST /api/v1/auth/change_password requires authentication' do
        post '/api/v1/auth/change_password', params: {
          current_password: 'Password123',
          password: 'NewPassword123'
        }, as: :json

        assert_response :unauthorized
      end

      test 'POST /api/v1/auth/change_password validates current password and password complexity' do
        # 1. Wrong current password
        post '/api/v1/auth/change_password', params: {
          current_password: 'WrongPassword123',
          password: 'NewPassword123'
        }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert_not json['success']
        assert_equal 'Incorrect current password.', json['message']

        # 2. Invalid/weak new password (missing uppercase)
        post '/api/v1/auth/change_password', params: {
          current_password: 'Password123',
          password: 'weakpassword123'
        }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json

        assert_response :unprocessable_entity
        json_weak = JSON.parse(response.body)
        assert_not json_weak['success']
        assert_includes json_weak['message'], 'Password must contain at least one uppercase letter'

        # 3. Successful change
        post '/api/v1/auth/change_password', params: {
          current_password: 'Password123',
          password: 'NewPassword123'
        }, headers: { 'Authorization' => "Bearer #{@token}" }, as: :json

        assert_response :ok
        json_ok = JSON.parse(response.body)
        assert json_ok['success']

        @user.reload
        assert @user.authenticate('NewPassword123')

        # 4. Verify login with new password works and old password fails
        post '/api/v1/auth/login', params: { email: @user.email, password: 'Password123' }, as: :json
        assert_response :unauthorized

        post '/api/v1/auth/login', params: { email: @user.email, password: 'NewPassword123' }, as: :json
        assert_response :ok
        login_json = JSON.parse(response.body)
        assert login_json['success']
        assert login_json['token']
      end
    end
  end
end
