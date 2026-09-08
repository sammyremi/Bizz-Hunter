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

        # Resolve and validate prospecting profile ownership
        selected_profile = nil
        profile_id = business_discovery_params[:prospecting_profile_id]

        if profile_id.present?
          if current_user.blank?
            return render json: {
              success: false,
              message: 'Authentication required to use a prospecting profile'
            }, status: :unauthorized
          end

          selected_profile = current_user.prospecting_profiles.find_by(id: profile_id)

          if selected_profile.nil?
            return render json: {
              success: false,
              message: 'Prospecting profile not found'
            }, status: :unprocessable_entity
          end
        end

        result = GooglePlaces::BusinessDiscovery.call(
          **business_discovery_params.except(:prospecting_profile_id).to_h.symbolize_keys
        )

        # Apply personalized (or generic) opportunity scoring to each business
        scored_result = result.map do |business|
          opp = OpportunityScoreCalculator.call(business: business, profile: selected_profile)
          business.merge(
            opportunity_score:   opp[:score],
            opportunity_tier:    opp[:tier],
            opportunity_level:   opp[:level],
            opportunity_factors: opp[:factors],
            opportunity_signals: opp[:signals],
            personalized_score:  opp[:personalized]
          )
        end

        saved_search = GooglePlaces::SearchPersistence.call(
          user:                current_user,
          search_params:       business_discovery_params.to_h,
          businesses:          scored_result,
          prospecting_profile: selected_profile
        )

        profile_summary = selected_profile ? {
          id:      selected_profile.id,
          name:    selected_profile.name,
          service: selected_profile.service
        } : nil

        render json: {
          success:             true,
          message:             'Businesses retrieved successfully',
          data:                scored_result,
          search_id:           saved_search&.id,
          prospecting_profile: profile_summary,
          quota:               quota_result[:quota]
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