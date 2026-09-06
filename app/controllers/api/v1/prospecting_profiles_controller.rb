# app/controllers/api/v1/prospecting_profiles_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class ProspectingProfilesController < ApplicationController
      include ProspectingProfilesConcern

      before_action :authenticate_user!
      before_action :set_prospecting_profile, only: %i[show update destroy]

      def index
        profiles = current_user.prospecting_profiles.order(created_at: :desc)
        render json: {
          success: true,
          data: ProspectingProfileSerializer.render(profiles)
        }, status: :ok
      end

      def show
        render json: {
          success: true,
          data: ProspectingProfileSerializer.render(@prospecting_profile)
        }, status: :ok
      end

      def create
        result = ProspectingProfiles::Create.call(user: current_user, params: prospecting_profile_params)

        if result[:success]
          render json: {
            success: true,
            data: ProspectingProfileSerializer.render(result[:profile]),
            message: result[:message]
          }, status: :created
        else
          render json: {
            success: false,
            message: result[:message],
            errors: result[:errors]
          }, status: :unprocessable_entity
        end
      end

      def update
        result = ProspectingProfiles::Update.call(
          prospecting_profile: @prospecting_profile,
          params: prospecting_profile_params
        )

        if result[:success]
          render json: {
            success: true,
            data: ProspectingProfileSerializer.render(result[:profile]),
            message: result[:message]
          }, status: :ok
        else
          render json: {
            success: false,
            message: result[:message],
            errors: result[:errors]
          }, status: :unprocessable_entity
        end
      end

      def destroy
        result = ProspectingProfiles::Destroy.call(prospecting_profile: @prospecting_profile)
        render json: {
          success: true,
          message: result[:message]
        }, status: :ok
      end

      private

      def set_prospecting_profile
        @prospecting_profile = current_user.prospecting_profiles.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          message: 'Prospecting profile not found'
        }, status: :not_found
      end
    end
  end
end
