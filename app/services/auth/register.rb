# app/services/auth/register.rb

# frozen_string_literal: true

module Auth
  class Register < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      user = User.new(params)

      if user.save
        token = JsonWebToken.encode(user_id: user.id)
        {
          success: true,
          user: user,
          token: token,
          message: 'Account created successfully'
        }
      else
        {
          success: false,
          user: nil,
          token: nil,
          message: user.errors.full_messages.join(', ')
        }
      end
    end

    private

    attr_reader :params
  end
end
