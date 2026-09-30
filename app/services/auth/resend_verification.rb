# app/services/auth/resend_verification.rb
# frozen_string_literal: true

module Auth
  class ResendVerification < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      return { success: false, error: 'User is required.' } unless user

      if user.verified?
        return { success: true, message: 'Your email address is already verified.' }
      end

      # Rate limiting: minimum 1 minute between verification emails
      if user.verification_sent_at.present? && user.verification_sent_at > 1.minute.ago
        return { success: false, error: 'Please wait a minute before requesting another verification email.' }
      end

      raw_token = user.generate_verification_token!
      begin
        UserMailer.verification_email(user, raw_token).deliver_now
      rescue StandardError => e
        Rails.logger.error("[Auth::ResendVerification] Delivery error: #{e.class.name} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      end

      { success: true, message: 'Verification email sent. Please check your inbox.' }
    end

    private

    attr_reader :user
  end
end
