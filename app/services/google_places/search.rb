module GooglePlaces
  class Search
    include HTTParty

    base_uri "https://places.googleapis.com/v1"

    def initialize(query:)
      @query = query
    end

    def call
      response = self.class.post(
        "/places:searchText",
        headers: {
          "Content-Type" => "application/json",
          "X-Goog-Api-Key" => ENV.fetch("GOOGLE_PLACES_API_KEY"),
          "X-Goog-FieldMask" => field_mask
        },
        body: {
          textQuery: @query
        }.to_json
      )

      JSON.parse(response.body)
    end

    private

    def field_mask
      [
        "places.id",
        "places.displayName",
        "places.formattedAddress",
        "places.location",
        "places.rating",
        "places.userRatingCount",
        "places.types",
        "places.googleMapsUri"
      ].join(",")
    end
  end
end