# app/services/auth/register.rb
# frozen_string_literal: true

module Auth
  class Register < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      user = User.new(params)

      return failure(user.errors.full_messages.join(', ')) unless user.valid?

      raw_verification_token = nil

      # Wrap user creation and token generation in a transaction so both
      # succeed or both roll back — no orphaned users with missing tokens.
      ActiveRecord::Base.transaction do
        user.save!
        raw_verification_token = user.generate_verification_token!
      end

      token = JsonWebToken.encode(user_id: user.id)

      # Send verification email outside the transaction (network failure
      # should not roll back the already-committed user record).
      begin
        UserMailer.verification_email(user, raw_verification_token).deliver_now
      rescue StandardError => e
        Rails.logger.error("[Auth::Register] Failed to deliver verification email: #{e.message}")
      end

      {
        success: true,
        user: user,
        token: token,
        message: 'Account created. Please check your email to verify your account.'
      }
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.join(', '))
    rescue StandardError => e
      Rails.logger.error("[Auth::Register] Unexpected error: #{e.message}")
      failure('Registration failed. Please try again.')
    end

    private

    attr_reader :params

    def failure(message)
      { success: false, user: nil, token: nil, message: message }
    end
  end
end
