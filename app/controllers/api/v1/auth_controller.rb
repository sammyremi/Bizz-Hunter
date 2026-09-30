# app/controllers/api/v1/auth_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      include AuthConcern

      before_action :authenticate_user!, only: %i[me logout resend_verification change_password]

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

      def verify_email
        result = Auth::VerifyEmail.call(token: params[:token])

        if result[:success]
          render json: {
            success: true,
            user: UserSerializer.render(result[:user]),
            message: 'Email verified successfully.'
          }, status: :ok
        else
          render json: {
            success: false,
            message: result[:error]
          }, status: :unprocessable_entity
        end
      end

      def resend_verification
        result = Auth::ResendVerification.call(user: current_user)

        if result[:success]
          render json: {
            success: true,
            message: result[:message]
          }, status: :ok
        else
          render json: {
            success: false,
            message: result[:error]
          }, status: :unprocessable_entity
        end
      end

      def forgot_password
        result = Auth::ForgotPassword.call(email: params[:email])

        render json: {
          success: true,
          message: result[:message]
        }, status: :ok
      end

      def reset_password
        result = Auth::ResetPassword.call(
          token: params[:token],
          password: params[:password]
        )

        if result[:success]
          render json: {
            success: true,
            user: UserSerializer.render(result[:user]),
            message: 'Password reset successfully. You can now log in.'
          }, status: :ok
        else
          render json: {
            success: false,
            message: result[:error]
          }, status: :unprocessable_entity
        end
      end

      def change_password
        cp = params[:current_password] || params.dig(:auth, :current_password)
        np = params[:password] || params.dig(:auth, :password)

        result = Auth::ChangePassword.call(
          user: current_user,
          current_password: cp,
          password: np
        )

        if result[:success]
          render json: {
            success: true,
            message: result[:message]
          }, status: :ok
        else
          render json: {
            success: false,
            message: result[:error]
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
