# app/services/auth/verify_email.rb
# frozen_string_literal: true

module Auth
  class VerifyEmail < ApplicationService
    def initialize(token:)
      @token = token
    end

    def call
      User.verify_email(token)
    end

    private

    attr_reader :token
  end
end
