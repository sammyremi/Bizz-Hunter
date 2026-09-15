# app/controllers/api/v1/outreach_messages_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class OutreachMessagesController < ApplicationController
      before_action :authenticate_user!

      def create
        search_result_id = params[:search_result_id] || params[:id]

        if search_result_id.blank?
          return render json: {
            success: false,
            message: 'search_result_id is required'
          }, status: :unprocessable_entity
        end

        # Resolve SearchResult belonging to current_user
        search_result = current_user.search_results.find_by(id: search_result_id) ||
                        current_user.search_results.where(google_place_id: search_result_id).order(created_at: :desc).first

        if search_result.nil?
          return render json: {
            success: false,
            message: 'Search result not found or unauthorized'
          }, status: :not_found
        end

        result = Ai::OutreachMessageGenerator.call(
          search_result: search_result,
          user:          current_user
        )

        if result[:success]
          render json: {
            success: true,
            data:    result[:data]
          }, status: :ok
        else
          render json: {
            success: false,
            message: result[:message] || 'Failed to generate outreach message'
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
