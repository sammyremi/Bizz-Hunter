# app/services/google_places/business_discovery_analysis.rb

# frozen_string_literal: true

module GooglePlaces
  class BusinessDiscoveryAnalysis < ApplicationService
    def initialize(businesses: nil, search: nil)
      @search_obj = search
      if search.present?
        @search_meta = {
          id: search.id,
          query: search.query,
          business_type: search.business_type,
          location_name: search.location_name,
          results_count: search.results_count,
          created_at: search.created_at
        }
        raw_list = search.search_results.map do |r|
          {
            id: r.google_place_id,
            google_place_id: r.google_place_id,
            name: r.name,
            types: r.types,
            address: r.address,
            phone: r.phone,
            national_phone: r.national_phone,
            website: r.website,
            rating: r.rating,
            review_count: r.review_count,
            opportunity_score: r.opportunity_score,
            opportunity_tier: r.opportunity_tier,
            opportunity_level: r.opportunity_level,
            opportunity_factors: r.opportunity_factors
          }
        end
        @businesses = raw_list.map(&:with_indifferent_access)
      else
        @search_meta = nil
        @businesses = Array(businesses).map(&:with_indifferent_access)
      end
    end

    def call
      return empty_analysis if businesses.empty?

      total_businesses = businesses.size

      no_website_count = 0
      has_website_count = 0

      phone_available_count = 0
      whatsapp_available_count = 0
      no_phone_count = 0

      high_opportunity_count = 0
      medium_opportunity_count = 0
      low_opportunity_count = 0

      type_counts = Hash.new(0)
      location_counts = Hash.new(0)

      rating_buckets = {
        '5.0' => 0,
        '4.5-4.9' => 0,
        '4.0-4.4' => 0,
        '3.5-3.9' => 0,
        'Below 3.5' => 0
      }

      scored_businesses = businesses.map do |b|
        # Ensure opportunity score is calculated if missing
        unless b.key?(:opportunity_score) && b[:opportunity_score].present?
          opp = OpportunityScoreCalculator.call(b)
          b[:opportunity_score] = opp[:score]
          b[:opportunity_tier] = opp[:tier]
          b[:opportunity_level] = opp[:level]
          b[:opportunity_factors] = opp[:factors]
          b[:opportunity_signals] = opp[:signals]
        end

        score = b[:opportunity_score].to_i
        tier = b[:opportunity_tier] || (score >= 80 ? 'high' : (score >= 50 ? 'medium' : 'low'))

        case tier
        when 'high'
          high_opportunity_count += 1
        when 'medium'
          medium_opportunity_count += 1
        else
          low_opportunity_count += 1
        end

        # Website
        if b[:website].present?
          has_website_count += 1
        else
          no_website_count += 1
        end

        # Phone & WhatsApp
        phone = b[:phone] || b[:national_phone] || b[:phone_number] || b[:international_phone_number]
        has_phone = phone.present?

        if has_phone
          phone_available_count += 1
          digits = phone.to_s.gsub(/\D/, '')
          if digits.length >= 7
            whatsapp_available_count += 1
          end
        else
          no_phone_count += 1
        end

        # Business Types
        raw_types = Array(b[:types])
        clean_types = raw_types.reject { |t| %w[point_of_interest establishment business].include?(t.to_s.downcase) }
        clean_types = [b[:primary_type] || 'Business'] if clean_types.empty?
        clean_types.each do |t|
          human_type = t.to_s.tr('_', ' ').strip.titleize
          type_counts[human_type] += 1
        end

        # Location extraction from address
        location_name = extract_location(b[:address])
        location_counts[location_name] += 1 if location_name.present?

        # Rating buckets
        r = b[:rating].to_f
        if r >= 5.0
          rating_buckets['5.0'] += 1
        elsif r >= 4.5
          rating_buckets['4.5-4.9'] += 1
        elsif r >= 4.0
          rating_buckets['4.0-4.4'] += 1
        elsif r >= 3.5
          rating_buckets['3.5-3.9'] += 1
        elsif r > 0
          rating_buckets['Below 3.5'] += 1
        end

        b
      end

      sorted_types = type_counts.map { |type, count| { 'type' => type, 'count' => count } }
                                .sort_by { |item| -item['count'] }
                                .first(10)

      sorted_locations = location_counts.map { |name, count| { 'name' => name, 'count' => count } }
                                        .sort_by { |item| -item['count'] }
                                        .first(10)

      formatted_ratings = rating_buckets.map { |range, count| { 'range' => range, 'count' => count } }

      top_prospects = scored_businesses.sort_by { |b| -b[:opportunity_score].to_i }.first(10)

      {
        search: @search_meta,
        summary: {
          total_businesses: total_businesses,
          no_website_count: no_website_count,
          phone_available_count: phone_available_count,
          whatsapp_available_count: whatsapp_available_count,
          high_opportunity_count: high_opportunity_count
        },
        opportunity: {
          high: high_opportunity_count,
          medium: medium_opportunity_count,
          low: low_opportunity_count
        },
        website: {
          no_website: no_website_count,
          has_website: has_website_count
        },
        contactability: {
          phone_available: phone_available_count,
          whatsapp_available: whatsapp_available_count,
          no_phone: no_phone_count
        },
        business_types: sorted_types,
        locations: sorted_locations,
        ratings: formatted_ratings,
        top_prospects: top_prospects
      }
    end

    private

    attr_reader :businesses, :search_meta, :search_obj

    def empty_analysis
      {
        search: search_meta,
        summary: {
          total_businesses: 0,
          no_website_count: 0,
          phone_available_count: 0,
          whatsapp_available_count: 0,
          high_opportunity_count: 0
        },
        opportunity: { high: 0, medium: 0, low: 0 },
        website: { no_website: 0, has_website: 0 },
        contactability: { phone_available: 0, whatsapp_available: 0, no_phone: 0 },
        business_types: [],
        locations: [],
        ratings: [
          { 'range' => '5.0', 'count' => 0 },
          { 'range' => '4.5-4.9', 'count' => 0 },
          { 'range' => '4.0-4.4', 'count' => 0 },
          { 'range' => '3.5-3.9', 'count' => 0 },
          { 'range' => 'Below 3.5', 'count' => 0 }
        ],
        top_prospects: []
      }
    end

    def extract_location(address)
      return nil if address.blank?

      parts = address.split(',').map(&:strip)
      return parts[1] if parts.size >= 3
      return parts[0] if parts.size == 2

      address
    end
  end
end
