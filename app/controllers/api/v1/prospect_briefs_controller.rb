# app/controllers/api/v1/prospect_briefs_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class ProspectBriefsController < ApplicationController
      before_action :set_current_user_if_present

      def create
        quota_check = UsageQuotaTracker.check_feature(
          user: current_user,
          ip: request.remote_ip,
          feature: :prospect_briefs
        )

        unless quota_check[:allowed]
          return render json: {
            success: false,
            message: quota_check[:message],
            code: current_user.present? ? 'LIMIT_REACHED' : 'GUEST_LIMIT_REACHED',
            quota: quota_check[:quota]
          }, status: :too_many_requests
        end

        search_result_id = params[:search_result_id]
        search_id = params[:search_id]
        prospect_id = params[:prospect_id]
        google_place_id = params[:google_place_id]

        # 1. Lookup SearchResult (scoped to current_user if authenticated)
        search_result = nil
        if current_user.present? && search_result_id.present?
          search_result = current_user.search_results.find_by(id: search_result_id)
        end

        # 2. Lookup Prospect (scoped to current_user if authenticated)
        prospect = nil
        if current_user.present? && prospect_id.present?
          prospect = current_user.prospects.find_by(id: prospect_id)
        end

        # If prospect is found, try to locate associated search_result for profile resolution
        if prospect.present? && search_result.nil? && current_user.present?
          search_result = current_user.search_results.where(google_place_id: prospect.google_place_id).order(created_at: :desc).first
        end

        # If search_result is still nil, try finding by google_place_id if provided
        if search_result.nil? && google_place_id.present? && current_user.present?
          search_result = current_user.search_results.where(google_place_id: google_place_id).order(created_at: :desc).first
        end

        # Resolve business data hash from search_result, prospect, or passed business params
        business = if search_result.present?
                     search_result_to_hash(search_result)
                   elsif prospect.present?
                     prospect_to_hash(prospect)
                   elsif params[:business].present?
                     params[:business].to_unsafe_h.symbolize_keys
                   else
                     nil
                   end

        if business.nil?
          return render json: {
            success: false,
            message: 'Business data, valid search_result_id, or valid prospect_id is required'
          }, status: :not_found
        end

        # 3. Resolve prospecting profile from the Search (source of truth)
        selected_profile = nil

        if current_user.present?
          if search_result&.search&.prospecting_profile.present?
            selected_profile = search_result.search.prospecting_profile
          elsif search_id.present?
            search = current_user.searches.find_by(id: search_id)
            selected_profile = search&.prospecting_profile
          end

          if selected_profile.nil? && params[:prospecting_profile_id].present?
            selected_profile = current_user.prospecting_profiles.find_by(id: params[:prospecting_profile_id])
          end

          if selected_profile.nil?
            return render json: {
              success: false,
              message: 'This search does not have a prospecting profile associated with it. ' \
                       'Please select a Prospecting Profile before searching to enable AI Prospect Briefs.'
            }, status: :unprocessable_entity
          end
        end

        result = Ai::ProspectBriefGenerator.call(
          business: business,
          prospecting_profile: selected_profile,
          user: current_user
        )

        if result[:success]
          UsageQuotaTracker.increment_feature!(
            user: current_user,
            ip: request.remote_ip,
            feature: :prospect_briefs
          )

          render json: {
            success: true,
            data: result[:data]
          }, status: :ok
        else
          render json: {
            success: false,
            message: result[:message] || 'Failed to generate prospect brief'
          }, status: :unprocessable_entity
        end
      end

      private

      def search_result_to_hash(sr)
        {
          id: sr.id,
          google_place_id: sr.google_place_id,
          name: sr.name,
          category: sr.try(:category) || sr.try(:business_type) || sr.try(:types)&.first,
          address: sr.address,
          phone: sr.phone,
          national_phone: sr.try(:national_phone),
          international_phone_number: sr.try(:international_phone_number),
          website: sr.website,
          rating: sr.rating,
          review_count: sr.review_count,
          opportunity_score: sr.opportunity_score,
          opportunity_tier: sr.opportunity_tier,
          opportunity_level: sr.opportunity_level,
          opportunity_factors: sr.opportunity_factors
        }
      end

      def prospect_to_hash(pr)
        {
          id: pr.id,
          google_place_id: pr.google_place_id,
          name: pr.try(:name) || pr.try(:business_name),
          category: pr.try(:category) || pr.try(:business_type),
          address: pr.address,
          phone: pr.try(:phone) || pr.try(:phone_number),
          national_phone: pr.try(:national_phone),
          international_phone_number: pr.try(:international_phone_number),
          website: pr.website,
          rating: pr.rating,
          review_count: pr.review_count,
          opportunity_score: pr.opportunity_score,
          opportunity_tier: pr.opportunity_tier,
          opportunity_level: pr.opportunity_level,
          opportunity_factors: pr.opportunity_factors
        }
      end
    end
  end
end
