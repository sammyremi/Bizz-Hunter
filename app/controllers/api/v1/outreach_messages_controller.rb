# app/controllers/api/v1/outreach_messages_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class OutreachMessagesController < ApplicationController
      before_action :set_current_user_if_present

      def create
        quota_check = UsageQuotaTracker.check_feature(
          user: current_user,
          ip: request.remote_ip,
          feature: :whatsapp_messages
        )

        unless quota_check[:allowed]
          return render json: {
            success: false,
            message: quota_check[:message],
            code: current_user.present? ? 'LIMIT_REACHED' : 'GUEST_LIMIT_REACHED',
            quota: quota_check[:quota]
          }, status: :too_many_requests
        end

        search_result_id = params[:search_result_id] || params[:id]

        if search_result_id.blank? && params[:business].blank?
          return render json: {
            success: false,
            message: 'search_result_id or business data is required'
          }, status: :unprocessable_entity
        end

        search_result = nil

        if current_user.present?
          search_result = current_user.search_results.find_by(id: search_result_id) ||
                          current_user.search_results.where(google_place_id: search_result_id).order(created_at: :desc).first
        else
          # For guest users, try finding search result by ID / place_id or build transient result
          if search_result_id.present?
            search_result = SearchResult.find_by(id: search_result_id) ||
                            SearchResult.where(google_place_id: search_result_id).order(created_at: :desc).first
          end

          if search_result.nil? && params[:business].present?
            b = params[:business].to_unsafe_h.symbolize_keys
            default_profile = ProspectingProfile.new(
              name: 'General Prospecting',
              service: 'B2B Services',
              service_description: 'Professional B2B Services'
            )
            dummy_search = Search.new(prospecting_profile: default_profile)
            search_result = SearchResult.new(
              search: dummy_search,
              name: b[:name] || b[:business_name] || 'Business',
              phone: b[:phone] || b[:phone_number] || b[:international_phone_number],
              national_phone: b[:national_phone],
              website: b[:website],
              address: b[:address],
              business_type: b[:category] || b[:business_type]
            )
          end
        end

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
          UsageQuotaTracker.increment_feature!(
            user: current_user,
            ip: request.remote_ip,
            feature: :whatsapp_messages
          )

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
