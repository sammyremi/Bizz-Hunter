# app/controllers/api/v1/business_discovery_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class BusinessDiscoveryController < ApplicationController
      include BusinessDiscoveryConcern

      before_action :set_current_user_if_present
      before_action :authenticate_user!, only: [:analysis]

      def quota
        status = SearchQuotaTracker.status(user: current_user, ip: request.remote_ip)
        render json: {
          success: true,
          quota: status
        }, status: :ok
      end

      def search
        quota_result = SearchQuotaTracker.check_and_increment!(
          user: current_user,
          ip: request.remote_ip
        )

        unless quota_result[:allowed]
          return render json: {
            success: false,
            message: quota_result[:message],
            quota: quota_result[:quota]
          }, status: :too_many_requests
        end

        result = GooglePlaces::BusinessDiscovery.call(
          **business_discovery_params.to_h.symbolize_keys
        )

        saved_search = GooglePlaces::SearchPersistence.call(
          user: current_user,
          search_params: business_discovery_params.to_h,
          businesses: result
        )

        render json: {
          success: true,
          message: 'Businesses retrieved successfully',
          data: result,
          search_id: saved_search&.id,
          quota: quota_result[:quota]
        }, status: :ok
      end

      def analysis
        search_record = if params[:search_id].present?
                          current_user.searches.find_by(id: params[:search_id])
                        else
                          current_user.searches.recent.first
                        end

        if search_record.present?
          analysis_data = GooglePlaces::BusinessDiscoveryAnalysis.call(search: search_record)
          return render json: { success: true, data: analysis_data }, status: :ok
        end

        if business_discovery_params[:business_type].present?
          result = GooglePlaces::BusinessDiscovery.call(
            **business_discovery_params.to_h.symbolize_keys
          )

          saved_search = GooglePlaces::SearchPersistence.call(
            user: current_user,
            search_params: business_discovery_params.to_h,
            businesses: result
          )

          analysis_data = GooglePlaces::BusinessDiscoveryAnalysis.call(
            search: saved_search,
            businesses: result
          )

          return render json: { success: true, data: analysis_data }, status: :ok
        end

        analysis_data = GooglePlaces::BusinessDiscoveryAnalysis.call(businesses: [])
        render json: { success: true, data: analysis_data }, status: :ok
      end
    end
  end
end