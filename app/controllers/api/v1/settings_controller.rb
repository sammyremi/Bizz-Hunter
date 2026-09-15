# app/controllers/api/v1/settings_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class SettingsController < ApplicationController
      before_action :authenticate_user!

      def show
        render json: {
          success: true,
          data: {
            ai_tone:   current_user.effective_ai_tone,
            ai_length: current_user.effective_ai_length
          }
        }, status: :ok
      end

      def update
        if current_user.update(settings_params)
          render json: {
            success: true,
            message: 'Settings updated successfully',
            data: {
              ai_tone:   current_user.effective_ai_tone,
              ai_length: current_user.effective_ai_length
            }
          }, status: :ok
        else
          render json: {
            success: false,
            message: 'Failed to update settings',
            errors:  current_user.errors
          }, status: :unprocessable_entity
        end
      end

      private

      def settings_params
        params.permit(:ai_tone, :ai_length)
      end
    end
  end
end
