# app/services/google_places/location_details.rb

# frozen_string_literal: true

module GooglePlaces
  class LocationDetails < ApplicationService
    include HTTParty

    BASE_URL = 'https://places.googleapis.com/v1/places'

    def initialize(place_id:)
      @place_id = place_id.to_s.gsub('places/', '').strip
    end

    def call
      return nil if place_id.blank?

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
        'formattedAddress',
        'location',
        'addressComponents'
      ].join(',')
    end

    def handle_response(response)
      return parse_location_details(response.parsed_response) if response.success?

      raise StandardError, response.parsed_response.dig('error', 'message') || 'Unable to fetch place location details'
    end

    def parse_location_details(data)
      components = data['addressComponents'] || []

      country_comp = components.find { |c| c['types']&.include?('country') }
      admin_comp = components.find { |c| c['types']&.include?('administrative_area_level_1') }
      locality_comp = components.find { |c| c['types']&.include?('locality') }
      sublocality_comp = components.find { |c| c['types']&.include?('sublocality') || c['types']&.include?('sublocality_level_1') }

      {
        place_id: data['id'] || place_id,
        name: data.dig('displayName', 'text') || data['formattedAddress'],
        formatted_address: data['formattedAddress'],
        latitude: data.dig('location', 'latitude'),
        longitude: data.dig('location', 'longitude'),
        country: country_comp&.dig('longText'),
        country_code: country_comp&.dig('shortText'),
        administrative_area: admin_comp&.dig('longText'),
        locality: locality_comp&.dig('longText'),
        sublocality: sublocality_comp&.dig('longText')
      }
    end
  end
end
