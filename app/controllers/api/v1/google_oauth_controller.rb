# app/controllers/api/v1/google_oauth_controller.rb
# frozen_string_literal: true

module Api
  module V1
    # Handles Google OAuth 2.0 Authorization Code flow.
    #
    # GET  /api/v1/auth/google          → redirect browser to Google consent screen
    # GET  /api/v1/auth/google/callback → receive code, exchange, issue JWT, redirect SPA
    #
    # This controller does NOT inherit ApplicationController's authenticate_user!
    # because neither action requires an authenticated user. It also does not use
    # cookies or sessions (this is a Rails API-only app).
    class GoogleOauthController < ActionController::Base
      # Allow browser redirects to external domains (Google) and back to SPA root
      # Use only the minimum ActionController features we need
      include ActionController::Cookies

      FRONTEND_ROOT = '/'

      # ------------------------------------------------------------------
      # Step 1 — Redirect browser to Google's OAuth consent screen
      # ------------------------------------------------------------------
      def redirect_to_google
        state = SecureRandom.hex(24)

        url = Auth::GoogleOauth.authorization_url(
          redirect_uri: callback_url,
          state:        state
        )

        redirect_to url, allow_other_host: true
      end

      # ------------------------------------------------------------------
      # Step 2 — Google redirects back here with ?code= and ?state=
      # ------------------------------------------------------------------
      def callback
        if params[:error].present?
          Rails.logger.warn("[GoogleOAuth] User denied consent or error: #{params[:error]}")
          return redirect_to_frontend(error: 'Google sign-in was cancelled.')
        end

        code = params[:code]
        unless code.present?
          return redirect_to_frontend(error: 'No authorization code received from Google.')
        end

        # Exchange authorization code for Google profile
        exchange_result = Auth::GoogleOauth.exchange_code(
          code:         code,
          redirect_uri: callback_url
        )

        unless exchange_result[:success]
          return redirect_to_frontend(error: exchange_result[:error])
        end

        # Find or create local user and issue JWT
        auth_result = Auth::GoogleOauth.find_or_create_user(exchange_result[:profile])

        unless auth_result[:success]
          return redirect_to_frontend(error: auth_result[:error])
        end

        # Success — redirect SPA with JWT in the URL fragment.
        # The fragment (#) is never sent to the server, so the token is not
        # captured in web server access logs.
        redirect_to "#{FRONTEND_ROOT}#oauth_token=#{ERB::Util.url_encode(auth_result[:token])}",
                    allow_other_host: false
      end

      private

      def callback_url
        "#{request.base_url}/auth/google_oauth2/callback"
      end

      def redirect_to_frontend(error:)
        encoded = ERB::Util.url_encode(error)
        redirect_to "#{FRONTEND_ROOT}#oauth_error=#{encoded}", allow_other_host: false
      end
    end
  end
end
