# app/services/auth/change_password.rb
# frozen_string_literal: true

module Auth
  class ChangePassword < ApplicationService
    def initialize(user:, current_password:, password:)
      @user = user
      @current_password = current_password
      @password = password
    end

    def call
      return { success: false, error: 'User is required.' } unless user

      # Require correct current password for email/password accounts
      if user.password_digest.present?
        unless current_password.present? && user.authenticate(current_password)
          return { success: false, error: 'Incorrect current password.' }
        end
      end

      user.password = password

      if user.save
        { success: true, message: 'Password updated successfully.' }
      else
        { success: false, error: user.errors.full_messages.join(', ') }
      end
    end

    private

    attr_reader :user, :current_password, :password
  end
end
