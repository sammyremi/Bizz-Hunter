# app/services/auth/reset_password.rb
# frozen_string_literal: true

module Auth
  class ResetPassword < ApplicationService
    def initialize(token:, password:)
      @token = token
      @password = password
    end

    def call
      User.reset_password_with_token(token, password)
    end

    private

    attr_reader :token, :password
  end
end
