# app/controllers/api/v1/analytics_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class AnalyticsController < ApplicationController
      before_action :authenticate_user!

      def show
        data = Analytics::UserAnalytics.call(user: current_user)
        render json: {
          success: true,
          data: data
        }, status: :ok
      end
    end
  end
end
