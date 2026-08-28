# frozen_string_literal: true

module GooglePlaces
  class BusinessDiscovery < ApplicationService
    def initialize(**params)
      @params = params
    end

    def call
      search_results = BusinessSearch.call(**params)

      businesses = search_results.fetch('places', [])

      businesses.map do |business|
        details = PlaceDetails.call(
          place_id: business['id']
        )

        normalize_business(details)
      end
    end

    private

    attr_reader :params

    def normalize_business(place)
      {
        id: place['id'],
        name: place.dig('displayName', 'text'),
        types: place['types'],
        address: place['formattedAddress'],
        latitude: place.dig('location', 'latitude'),
        longitude: place.dig('location', 'longitude'),
        rating: place['rating'],
        review_count: place['userRatingCount'],
        phone: place['internationalPhoneNumber'],
        national_phone: place['nationalPhoneNumber'],
        website: place['websiteUri'],
        google_maps_url: place['googleMapsUri']
      }
    end
  end
end