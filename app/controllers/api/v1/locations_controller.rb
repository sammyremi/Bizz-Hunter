# app/controllers/api/v1/locations_controller.rb

# frozen_string_literal: true

module Api
  module V1
    class LocationsController < ApplicationController
      include LocationsConcern

      def autocomplete
        input = autocomplete_input_param
        if input.blank? || input.length < 2
          return render json: { success: true, data: [] }, status: :ok
        end

        results = GooglePlaces::LocationAutocomplete.call(input: input)
        render json: { success: true, data: results }, status: :ok
      rescue StandardError => e
        render json: { success: false, message: e.message }, status: :unprocessable_entity
      end

      def details
        place_id = place_id_param
        if place_id.blank?
          return render json: { success: false, message: 'place_id parameter is required' }, status: :bad_request
        end

        details = GooglePlaces::LocationDetails.call(place_id: place_id)
        render json: { success: true, data: details }, status: :ok
      rescue StandardError => e
        render json: { success: false, message: e.message }, status: :unprocessable_entity
      end
    end
  end
end
