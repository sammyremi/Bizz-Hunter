# app/services/google_places/business_search.rb

# frozen_string_literal: true

module GooglePlaces
  class BusinessSearch < ApplicationService
    include HTTParty

    BASE_URL = 'https://places.googleapis.com/v1/places:searchText'

    def initialize(
      business_type:,
      location_name: nil,
      place_id: nil,
      country: nil,
      region: nil,
      city: nil,
      area: nil
    )
      @business_type = business_type
      @location_name = location_name
      @place_id = place_id
      @country = country
      @region = region
      @city = city
      @area = area
    end

    def call
      response = self.class.post(
        BASE_URL,
        headers: headers,
        body: request_body.to_json
      )

      handle_response(response)
    end

    private

    attr_reader :business_type,
                :location_name,
                :place_id,
                :country,
                :region,
                :city,
                :area

    def request_body
      {
        textQuery: build_query,
        maxResultCount: 20
      }
    end

    def build_query
      if location_name.present?
        [business_type, location_name].compact_blank.join(', ')
      else
        [business_type, area, city, region, country].compact_blank.join(', ')
      end
    end

    def headers
      {
        'Content-Type' => 'application/json',
        'X-Goog-Api-Key' => ENV.fetch('GOOGLE_PLACES_API_KEY'),
        'X-Goog-FieldMask' => field_mask
      }
    end

    def field_mask
      [
        'places.id',
        'places.displayName',
        'places.formattedAddress',
        'places.location',
        'places.rating',
        'places.userRatingCount',
        'places.googleMapsUri'
      ].join(',')
    end

    def handle_response(response)
      return response.parsed_response if response.success?

      raise StandardError, response.parsed_response.dig('error', 'message') || 'Business search failed'
    end
  end
end