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
      area: nil,
      page_token: nil,
      page_size: 20
    )
      @business_type = business_type
      @location_name = location_name
      @place_id      = place_id
      @country       = country
      @region        = region
      @city          = city
      @area          = area
      @page_token    = page_token
      @page_size     = page_size.clamp(1, 20)
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
                :area,
                :page_token,
                :page_size

    def request_body
      body = {
        textQuery: build_query,
        maxResultCount: page_size
      }
      body[:pageToken] = page_token if page_token.present?
      body
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
        'places.googleMapsUri',
        'places.internationalPhoneNumber',
        'places.nationalPhoneNumber',
        'places.websiteUri',
        'places.types',
        'nextPageToken'
      ].join(',')
    end

    def handle_response(response)
      return response.parsed_response if response.success?

      error_msg = response.parsed_response.is_a?(Hash) ? response.parsed_response.dig('error', 'message') : nil
      error_msg ||= response.body.presence || "HTTP #{response.code} error"

      # Attach HTTP code and Retry-After header if present
      retry_after = response.headers['retry-after'] || response.headers['Retry-After']
      status_code = response.code.to_i

      ex = StandardError.new("#{status_code}: #{error_msg}")
      ex.instance_variable_set(:@http_status, status_code)
      ex.instance_variable_set(:@retry_after, retry_after ? retry_after.to_i : nil)

      def ex.http_status; @http_status; end
      def ex.retry_after; @retry_after; end

      raise ex
    end
  end
end