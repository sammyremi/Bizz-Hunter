require "httparty"

module GooglePlaces
  class BusinessSearch
    include HTTParty

    BASE_URL = "https://places.googleapis.com/v1/places:searchText"

    def initialize(query:)
      @query = query
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

    attr_reader :query

    def headers
      {
        "Content-Type" => "application/json",
        "X-Goog-Api-Key" => ENV.fetch("GOOGLE_MAPS_API_KEY"),
        "X-Goog-FieldMask" => field_mask
      }
    end

    def request_body
      {
        textQuery: query
      }
    end

    def field_mask
      [
        "places.id",
        "places.displayName",
        "places.formattedAddress",
        "places.location",
        "places.rating",
        "places.userRatingCount",
        "places.googleMapsUri"
      ].join(",")
    end

    def handle_response(response)
      return JSON.parse(response.body) if response.success?

      {
        error: "Google Places API request failed",
        status: response.code,
        message: response.body
      }
    end
  end
end