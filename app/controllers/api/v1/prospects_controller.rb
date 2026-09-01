# app/controllers/api/v1/prospects_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class ProspectsController < ApplicationController
      include ProspectsConcern

      before_action :authenticate_user!
      before_action :set_prospect, only: %i[show update destroy]

      def index
        prospects = current_user.prospects.by_status(filter_status_param).recent
        render json: {
          success: true,
          data: ProspectSerializer.render(prospects)
        }, status: :ok
      end

      def create
        result = Prospects::Create.call(user: current_user, params: prospect_create_params)

        if result[:success]
          render json: {
            success: true,
            data: ProspectSerializer.render(result[:prospect]),
            message: result[:message]
          }, status: result[:status]
        else
          render json: {
            success: false,
            message: result[:message]
          }, status: result[:status]
        end
      end

      def show
        render json: {
          success: true,
          data: ProspectSerializer.render(@prospect)
        }, status: :ok
      end

      def update
        result = Prospects::Update.call(prospect: @prospect, params: prospect_update_params)

        if result[:success]
          render json: {
            success: true,
            data: ProspectSerializer.render(result[:prospect]),
            message: result[:message]
          }, status: :ok
        else
          render json: {
            success: false,
            message: result[:message]
          }, status: :unprocessable_entity
        end
      end

      def destroy
        result = Prospects::Destroy.call(prospect: @prospect)
        render json: {
          success: true,
          message: result[:message]
        }, status: :ok
      end

      private

      def set_prospect
        @prospect = current_user.prospects.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, message: 'Prospect not found' }, status: :not_found
      end
    end
  end
end
