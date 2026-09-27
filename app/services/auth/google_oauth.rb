# app/services/auth/google_oauth.rb
# frozen_string_literal: true

module Auth
  # Handles the server-side Google OAuth 2.0 Authorization Code flow.
  #
  # Flow:
  #   1. authorization_url  — build the URL the browser navigates to
  #   2. exchange_code!     — exchange the authorization code for tokens + profile
  #   3. find_or_create_user — find/create a local User record, return JWT
  #
  # This service uses HTTParty (already a project dependency) so no new gems
  # are required. Client credentials are read exclusively from ENV.
  class GoogleOauth < ApplicationService
    GOOGLE_AUTH_URL  = 'https://accounts.google.com/o/oauth2/v2/auth'
    GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token'
    GOOGLE_USERINFO_URL = 'https://www.googleapis.com/oauth2/v3/userinfo'

    # -----------------------------------------------------------------------
    # Build the Google authorization URL the browser should be redirected to.
    # -----------------------------------------------------------------------
    def self.authorization_url(redirect_uri:, state: nil)
      params = {
        client_id:     ENV.fetch('GOOGLE_CLIENT_ID'),
        redirect_uri:  redirect_uri,
        response_type: 'code',
        scope:         'openid email profile',
        access_type:   'online',
        prompt:        'select_account'
      }
      params[:state] = state if state.present?

      "#{GOOGLE_AUTH_URL}?#{params.to_query}"
    end

    # -----------------------------------------------------------------------
    # Exchange an authorization code for a verified Google profile.
    # Returns { success: true, profile: {...} } or { success: false, error: '...' }
    # -----------------------------------------------------------------------
    def self.exchange_code(code:, redirect_uri:)
      token_response = HTTParty.post(
        GOOGLE_TOKEN_URL,
        body: {
          code:          code,
          client_id:     ENV.fetch('GOOGLE_CLIENT_ID'),
          client_secret: ENV.fetch('GOOGLE_CLIENT_SECRET'),
          redirect_uri:  redirect_uri,
          grant_type:    'authorization_code'
        },
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
        timeout: 10
      )

      unless token_response.success?
        error_body = token_response.parsed_response
        Rails.logger.error("[GoogleOAuth] Token exchange failed: #{error_body}")
        return { success: false, error: 'Failed to exchange authorization code with Google.' }
      end

      access_token = token_response.parsed_response['access_token']

      unless access_token.present?
        Rails.logger.error('[GoogleOAuth] No access_token in Google token response')
        return { success: false, error: 'No access token returned by Google.' }
      end

      # Fetch verified user profile from Google
      userinfo_response = HTTParty.get(
        GOOGLE_USERINFO_URL,
        headers: { 'Authorization' => "Bearer #{access_token}" },
        timeout: 10
      )

      unless userinfo_response.success?
        Rails.logger.error("[GoogleOAuth] Userinfo fetch failed: #{userinfo_response.parsed_response}")
        return { success: false, error: 'Failed to retrieve profile from Google.' }
      end

      info = userinfo_response.parsed_response

      # Google's /userinfo endpoint uses 'sub' as the unique identifier
      google_uid = info['sub']
      email      = info['email']

      unless google_uid.present? && email.present?
        Rails.logger.error('[GoogleOAuth] Missing sub or email in Google userinfo response')
        return { success: false, error: 'Incomplete profile returned by Google.' }
      end

      {
        success: true,
        profile: {
          uid:        google_uid,
          email:      email,
          name:       info['name'],
          avatar_url: info['picture']
        }
      }
    end

    # -----------------------------------------------------------------------
    # Find or create a local user from a verified Google profile, then issue
    # the same JWT used by the email/password flow.
    # Returns { success: true, user:, token: } or { success: false, error: }
    # -----------------------------------------------------------------------
    def self.find_or_create_user(profile)
      user = User.find_or_create_from_google(profile)
      token = JsonWebToken.encode(user_id: user.id)
      { success: true, user: user, token: token }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[GoogleOAuth] Failed to create user: #{e.message}")
      { success: false, error: 'Unable to create account. Please try again.' }
    end
  end
end
