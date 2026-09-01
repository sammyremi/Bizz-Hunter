# app/controllers/api/v1/auth_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      include AuthConcern

      before_action :authenticate_user!, only: %i[me logout]

      def register
        result = Auth::Register.call(register_params)

        if result[:success]
          render json: {
            success: true,
            token: result[:token],
            user: UserSerializer.render(result[:user]),
            message: result[:message]
          }, status: :created
        else
          render json: {
            success: false,
            message: result[:message]
          }, status: :unprocessable_entity
        end
      end

      def login
        result = Auth::Login.call(login_params)

        if result[:success]
          render json: {
            success: true,
            token: result[:token],
            user: UserSerializer.render(result[:user]),
            message: result[:message]
          }, status: :ok
        else
          render json: {
            success: false,
            message: result[:message]
          }, status: :unauthorized
        end
      end

      def me
        render json: {
          success: true,
          user: UserSerializer.render(current_user)
        }, status: :ok
      end

      def logout
        render json: {
          success: true,
          message: 'Logged out successfully'
        }, status: :ok
      end
    end
  end
end
