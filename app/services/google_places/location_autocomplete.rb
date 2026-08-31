# app/services/google_places/location_autocomplete.rb

# frozen_string_literal: true

module GooglePlaces
  class LocationAutocomplete < ApplicationService
    include HTTParty

    BASE_URL = 'https://places.googleapis.com/v1/places:autocomplete'

    def initialize(input:, language_code: 'en')
      @input = input.to_s.strip
      @language_code = language_code
    end

    def call
      return [] if input.blank? || input.length < 2

      response = self.class.post(
        BASE_URL,
        headers: headers,
        body: request_body.to_json
      )

      handle_response(response)
    end

    private

    attr_reader :input, :language_code

    def request_body
      {
        input: input,
        languageCode: language_code,
        includedPrimaryTypes: [
          'locality',
          'sublocality',
          'sublocality_level_1',
          'sublocality_level_2',
          'administrative_area_level_1',
          'administrative_area_level_2',
          'country',
          'postal_code'
        ]
      }
    end

    def headers
      {
        'Content-Type' => 'application/json',
        'X-Goog-Api-Key' => ENV.fetch('GOOGLE_PLACES_API_KEY')
      }
    end

    def handle_response(response)
      return parse_suggestions(response.parsed_response) if response.success?

      # Fallback to general autocomplete request if primary types filter is strict
      fallback_response = self.class.post(
        BASE_URL,
        headers: headers,
        body: { input: input, languageCode: language_code }.to_json
      )

      return parse_suggestions(fallback_response.parsed_response) if fallback_response.success?

      []
    end

    def parse_suggestions(data)
      return [] unless data.is_a?(Hash) && data['suggestions'].is_a?(Array)

      data['suggestions'].map do |item|
        prediction = item['placePrediction']
        next unless prediction

        raw_id = prediction['placeId'] || prediction['place']
        clean_id = raw_id.to_s.gsub('places/', '')
        main_txt = prediction.dig('structuredFormat', 'mainText', 'text') || prediction.dig('text', 'text')
        sec_txt = prediction.dig('structuredFormat', 'secondaryText', 'text')
        full_txt = prediction.dig('text', 'text') || [main_txt, sec_txt].compact.join(', ')

        {
          place_id: clean_id,
          name: main_txt,
          formatted_address: full_txt,
          main_text: main_txt,
          secondary_text: sec_txt,
          types: prediction['types'] || []
        }
      end.compact
    end
  end
end
