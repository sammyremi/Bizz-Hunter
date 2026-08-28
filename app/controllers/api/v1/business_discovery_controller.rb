# frozen_string_literal: true

module Api
  module V1
    class BusinessDiscoveryController < ApplicationController
      def search
        result = GooglePlaces::BusinessSearch.new(
          search_params
        ).call

        success(result, 'Businesses retrieved successfully')
      end

      private

      def search_params
        params.permit(
          :query,
          :location,
          :business_type,
          :min_rating,
          :has_phone,
          :has_website
        )
      end
    end
  end
end