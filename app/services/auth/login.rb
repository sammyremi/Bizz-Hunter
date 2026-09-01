# app/services/auth/login.rb

# frozen_string_literal: true

module Auth
  class Login < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      email = params[:email].to_s.strip.downcase
      password = params[:password]

      user = User.find_by(email: email)

      if user&.authenticate(password)
        token = JsonWebToken.encode(user_id: user.id)
        {
          success: true,
          user: user,
          token: token,
          message: 'Logged in successfully'
        }
      else
        {
          success: false,
          user: nil,
          token: nil,
          message: 'Invalid email or password'
        }
      end
    end

    private

    attr_reader :params
  end
end
