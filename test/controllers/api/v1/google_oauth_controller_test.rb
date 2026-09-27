# test/controllers/api/v1/google_oauth_controller_test.rb
# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class GoogleOauthControllerTest < ActionDispatch::IntegrationTest
      setup do
        ENV['GOOGLE_CLIENT_ID']     = 'test_client_id'
        ENV['GOOGLE_CLIENT_SECRET'] = 'test_client_secret'
      end

      test 'GET /api/v1/auth/google redirects to Google authorization URL with correct redirect_uri' do
        get '/api/v1/auth/google'

        assert_response :redirect
        assert_includes response.redirect_url, 'accounts.google.com/o/oauth2/v2/auth'
        assert_includes response.redirect_url, 'client_id=test_client_id'
        assert_includes response.redirect_url, 'redirect_uri=http%3A%2F%2Fwww.example.com%2Fauth%2Fgoogle_oauth2%2Fcallback'
      end

      test 'GET /auth/google_oauth2/callback with user cancellation redirects to frontend with error' do
        get '/auth/google_oauth2/callback', params: { error: 'access_denied' }

        assert_response :redirect
        assert_includes response.redirect_url, '#oauth_error='
        assert_includes response.redirect_url, 'cancelled'
      end

      test 'GET /auth/google_oauth2/callback with missing code redirects to frontend with error' do
        get '/auth/google_oauth2/callback'

        assert_response :redirect
        assert_includes response.redirect_url, '#oauth_error='
      end

      test 'GET /auth/google_oauth2/callback with valid code exchanges and redirects with token' do
        mock_profile_result = {
          success: true,
          profile: {
            uid:        'google_123',
            email:      'oauth_ctrl_test@example.com',
            name:       'OAuth Controller Test',
            avatar_url: 'https://example.com/avatar.jpg'
          }
        }

        with_stub(Auth::GoogleOauth, :exchange_code, mock_profile_result) do
          get '/auth/google_oauth2/callback', params: { code: 'valid_mock_code' }

          assert_response :redirect
          assert_includes response.redirect_url, '#oauth_token='

          user = User.find_by(email: 'oauth_ctrl_test@example.com')
          assert_not_nil user
          assert_equal 'google', user.provider
          assert_equal 'google_123', user.uid
        end
      end
    end
  end
end
