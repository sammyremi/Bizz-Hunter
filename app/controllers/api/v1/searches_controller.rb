# app/controllers/api/v1/searches_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class SearchesController < ApplicationController
      before_action :authenticate_user!

      def index
        searches = current_user.searches.recent.limit(20)
        serialized = searches.map do |s|
          {
            id: s.id,
            query: s.query,
            business_type: s.business_type,
            location_name: s.location_name,
            results_count: s.results_count,
            created_at: s.created_at
          }
        end

        render json: {
          success: true,
          data: serialized
        }, status: :ok
      end

      def analysis
        search = current_user.searches.find(params[:id])
        analysis_data = GooglePlaces::BusinessDiscoveryAnalysis.call(search: search)

        render json: {
          success: true,
          data: analysis_data
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          message: 'Search record not found or unauthorized'
        }, status: :not_found
      end
    end
  end
end
