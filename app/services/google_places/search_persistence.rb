# app/services/google_places/search_persistence.rb

# frozen_string_literal: true

module GooglePlaces
  class SearchPersistence < ApplicationService
    def initialize(user:, search_params:, businesses:)
      @user = user
      @search_params = search_params.symbolize_keys
      @businesses = Array(businesses).map(&:with_indifferent_access)
    end

    def call
      return nil if user.blank?

      search = user.searches.create!(
        business_type: search_params[:business_type],
        location_name: search_params[:location_name],
        country: search_params[:country],
        state: search_params[:state],
        city: search_params[:city],
        area: search_params[:area],
        min_rating: search_params[:min_rating],
        website_filter: search_params[:has_website],
        phone_filter: search_params[:has_phone],
        query: "#{search_params[:business_type]} in #{search_params[:location_name]}".strip,
        results_count: businesses.size
      )

      businesses.each do |b|
        opp = OpportunityScoreCalculator.call(b)

        search.search_results.create!(
          user: user,
          google_place_id: b[:id] || b[:google_place_id] || "place_#{SecureRandom.hex(8)}",
          name: b[:name] || b[:business_name] || 'Business',
          business_type: search_params[:business_type],
          types: Array(b[:types]),
          address: b[:address],
          latitude: b[:latitude],
          longitude: b[:longitude],
          phone: b[:phone] || b[:phone_number],
          national_phone: b[:national_phone],
          website: b[:website],
          google_maps_url: b[:google_maps_url],
          rating: b[:rating],
          review_count: b[:review_count] || b[:user_rating_count] || 0,
          opportunity_score: b[:opportunity_score] || opp[:score],
          opportunity_tier: b[:opportunity_tier] || opp[:tier],
          opportunity_level: b[:opportunity_level] || opp[:level],
          opportunity_factors: b[:opportunity_factors] || opp[:factors]
        )
      end

      search
    end

    private

    attr_reader :user, :search_params, :businesses
  end
end
