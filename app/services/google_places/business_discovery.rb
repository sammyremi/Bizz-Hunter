# app/services/google_places/business_discovery.rb

# frozen_string_literal: true

module GooglePlaces
  class BusinessDiscovery < ApplicationService
    def initialize(
      business_type:,
      location_name: nil,
      place_id: nil,
      country: nil,
      state: nil,
      city: nil,
      area: nil,
      min_rating: nil,
      has_phone: nil,
      has_website: nil
    )
      @business_type = business_type
      @location_name = location_name
      @place_id = place_id
      @country = country
      @state = state
      @city = city
      @area = area
      @min_rating = min_rating
      @has_phone = has_phone
      @has_website = has_website
    end

    def call
      search_results = BusinessSearch.call(
        business_type: business_type,
        location_name: location_name,
        place_id: place_id,
        country: country,
        region: state,
        city: city,
        area: area
      )

      businesses = search_results.fetch('places', [])

      businesses = filter_businesses(businesses)

      businesses.map do |business|
        details = PlaceDetails.call(
          place_id: business['id']
        )

        normalize_business(details)
      end
    end

    private

    attr_reader :business_type,
                :location_name,
                :place_id,
                :country,
                :state,
                :city,
                :area,
                :min_rating,
                :has_phone,
                :has_website

    def filter_businesses(businesses)
      businesses = businesses.select do |business|
        rating_matches?(business) &&
          phone_matches?(business) &&
          website_matches?(business)
      end

      businesses
    end

    def rating_matches?(business)
      return true if min_rating.blank?

      business['rating'].to_f >= min_rating.to_f
    end

    def phone_matches?(business)
      return true if has_phone.blank?

      has_phone.to_s == 'true' ? business_has_phone?(business) : !business_has_phone?(business)
    end

    def website_matches?(business)
      return true if has_website.blank?

      has_website.to_s == 'true' ? business_has_website?(business) : !business_has_website?(business)
    end

    def business_has_phone?(business)
      business['internationalPhoneNumber'].present? ||
        business['nationalPhoneNumber'].present?
    end

    def business_has_website?(business)
      business['websiteUri'].present?
    end

    def normalize_business(place)
      data = {
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

      opp = OpportunityScoreCalculator.call(data)
      data[:opportunity_score] = opp[:score]
      data[:opportunity_level] = opp[:level]
      data[:opportunity_signals] = opp[:signals]

      data
    end
  end
end