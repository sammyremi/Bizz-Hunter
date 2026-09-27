# test/services/auth/google_oauth_test.rb
# frozen_string_literal: true

require 'test_helper'

module Auth
  class GoogleOauthTest < ActiveSupport::TestCase
    setup do
      ENV['GOOGLE_CLIENT_ID']     = 'test_client_id'
      ENV['GOOGLE_CLIENT_SECRET'] = 'test_client_secret'
    end

    test 'authorization_url builds valid Google OAuth URL' do
      url = Auth::GoogleOauth.authorization_url(
        redirect_uri: 'http://localhost:4000/auth/google_oauth2/callback',
        state: 'test_state_123'
      )

      assert_includes url, 'https://accounts.google.com/o/oauth2/v2/auth'
      assert_includes url, 'client_id=test_client_id'
      assert_includes url, 'state=test_state_123'
      assert_includes url, 'response_type=code'
      assert_includes url, 'scope=openid+email+profile'
      assert_includes url, 'redirect_uri=http%3A%2F%2Flocalhost%3A4000%2Fauth%2Fgoogle_oauth2%2Fcallback'
    end

    test 'exchange_code handles HTTP failure gracefully' do
      stub_request_failure = Struct.new(:success?, :parsed_response).new(false, { 'error' => 'invalid_grant' })
      with_stub(HTTParty, :post, stub_request_failure) do
        result = Auth::GoogleOauth.exchange_code(
          code: 'bad_code',
          redirect_uri: 'http://localhost:4000/auth/google_oauth2/callback'
        )

        assert_equal false, result[:success]
        assert_equal 'Failed to exchange authorization code with Google.', result[:error]
      end
    end

    test 'exchange_code returns profile on successful code exchange' do
      token_resp = Struct.new(:success?, :parsed_response).new(true, { 'access_token' => 'mock_token' })
      userinfo_resp = Struct.new(:success?, :parsed_response).new(
        true,
        {
          'sub'     => 'google_12345',
          'email'   => 'test@example.com',
          'name'    => 'Test User',
          'picture' => 'https://example.com/pic.jpg'
        }
      )

      with_stub(HTTParty, :post, token_resp) do
        with_stub(HTTParty, :get, userinfo_resp) do
          result = Auth::GoogleOauth.exchange_code(
            code: 'valid_code',
            redirect_uri: 'http://localhost:4000/auth/google_oauth2/callback'
          )

          assert_equal true, result[:success]
          profile = result[:profile]
          assert_equal 'google_12345', profile[:uid]
          assert_equal 'test@example.com', profile[:email]
          assert_equal 'Test User', profile[:name]
          assert_equal 'https://example.com/pic.jpg', profile[:avatar_url]
        end
      end
    end

    test 'find_or_create_user returns JWT token for user' do
      profile = {
        uid:        'google_99999',
        email:      'service_test@example.com',
        name:       'Service Test',
        avatar_url: nil
      }

      result = Auth::GoogleOauth.find_or_create_user(profile)

      assert_equal true, result[:success]
      assert_instance_of User, result[:user]
      assert_not_nil result[:token]

      decoded = JsonWebToken.decode(result[:token])
      assert_equal result[:user].id, decoded[:user_id]
    end
  end
end
