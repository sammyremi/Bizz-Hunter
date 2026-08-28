# app/controllers/api/v1/business_discovery_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class BusinessDiscoveryController < ApplicationController
      include BusinessDiscoveryConcern

      def search
        result = GooglePlaces::BusinessDiscovery.call(
          **business_discovery_params.to_h.symbolize_keys
        )

        render json: {
          success: true,
          message: 'Businesses retrieved successfully',
          data: result
        }, status: :ok
      end
    end
  end
end