# app/services/auth/forgot_password.rb
# frozen_string_literal: true

module Auth
  class ForgotPassword < ApplicationService
    GENERIC_MESSAGE = 'If an account exists with that email address, password reset instructions have been sent.'

    def initialize(email:)
      @email = email.to_s.strip.downcase
    end

    def call
      user = User.find_by(email: email)

      if user
        # Rate limit: minimum 1 minute between password reset emails
        if user.reset_password_sent_at.present? && user.reset_password_sent_at > 1.minute.ago
          return { success: true, message: GENERIC_MESSAGE }
        end

        raw_token = user.generate_reset_password_token!
        begin
          UserMailer.password_reset_email(user, raw_token).deliver_now
        rescue StandardError => e
          Rails.logger.error("[Auth::ForgotPassword] Delivery error: #{e.class.name} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
        end
      end

      # ALWAYS return generic message to prevent account enumeration
      { success: true, message: GENERIC_MESSAGE }
    end

    private

    attr_reader :email
  end
end
