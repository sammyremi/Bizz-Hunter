# frozen_string_literal: true

module GooglePlaces
  class PlaceDetails < ApplicationService
    include HTTParty

    BASE_URL = 'https://places.googleapis.com/v1/places'

    def initialize(place_id:)
      @place_id = place_id
    end

    def call
      response = self.class.get(
        "#{BASE_URL}/#{place_id}",
        headers: headers
      )

      handle_response(response)
    end

    private

    attr_reader :place_id

    def headers
      {
        'Content-Type' => 'application/json',
        'X-Goog-Api-Key' => ENV.fetch('GOOGLE_PLACES_API_KEY'),
        'X-Goog-FieldMask' => field_mask
      }
    end

    def field_mask
      [
        'id',
        'displayName',
        'types',
        'formattedAddress',
        'location',
        'rating',
        'userRatingCount',
        'googleMapsUri',
        'internationalPhoneNumber',
        'nationalPhoneNumber',
        'websiteUri'
      ].join(',')
    end

    def handle_response(response)
      return response.parsed_response if response.success?

      raise StandardError, response.parsed_response.dig('error', 'message')
    end
  end
end