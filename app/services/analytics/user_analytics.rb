# app/services/analytics/user_analytics.rb

# frozen_string_literal: true

module Analytics
  class UserAnalytics < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      return empty_analytics if user.blank?

      results_scope = user.search_results
      searches_scope = user.searches
      prospects_scope = user.prospects

      total_businesses_found = results_scope.count
      total_searches = searches_scope.count
      saved_prospects_count = prospects_scope.count

      tier_counts = results_scope.group(:opportunity_tier).count
      high_opp = tier_counts['high'] || 0
      med_opp = tier_counts['medium'] || 0
      low_opp = tier_counts['low'] || 0

      no_website_count = results_scope.where("website IS NULL OR website = ''").count
      has_website_count = total_businesses_found - no_website_count

      phone_count = results_scope.where("phone IS NOT NULL AND phone != '' OR national_phone IS NOT NULL AND national_phone != ''").count
      no_phone_count = total_businesses_found - phone_count

      # WhatsApp reachable count from DB
      whatsapp_count = results_scope.select do |r|
        p = r.phone.presence || r.national_phone.presence
        p.present? && p.to_s.gsub(/\D/, '').length >= 7
      end.size

      # Top Business Types
      types_map = Hash.new(0)
      results_scope.pluck(:types, :business_type).each do |types_arr, main_type|
        clean = Array(types_arr).reject { |t| %w[point_of_interest establishment business].include?(t.to_s.downcase) }
        clean = [main_type || 'Business'] if clean.empty?
        clean.each do |t|
          human = t.to_s.tr('_', ' ').strip.titleize
          types_map[human] += 1
        end
      end

      top_types = types_map.map { |type, count| { 'type' => type, 'count' => count } }
                           .sort_by { |item| -item['count'] }
                           .first(5)

      # Discovery trend by date
      trend_hash = results_scope.group("DATE(created_at)").count
      discovery_trend = trend_hash.map { |date, count| { 'date' => date.to_s, 'count' => count } }
                                 .sort_by { |item| item['date'] }

      {
        businesses_found: total_businesses_found,
        high_opportunity: high_opp,
        medium_opportunity: med_opp,
        low_opportunity: low_opp,
        no_website: no_website_count,
        website_available: has_website_count,
        phone_available: phone_count,
        whatsapp_available: whatsapp_count,
        saved_prospects: saved_prospects_count,
        total_searches: total_searches,
        opportunity_breakdown: {
          high: high_opp,
          medium: med_opp,
          low: low_opp
        },
        top_business_types: top_types,
        discovery_trend: discovery_trend
      }
    end

    private

    attr_reader :user

    def empty_analytics
      {
        businesses_found: 0,
        high_opportunity: 0,
        medium_opportunity: 0,
        low_opportunity: 0,
        no_website: 0,
        website_available: 0,
        phone_available: 0,
        whatsapp_available: 0,
        saved_prospects: 0,
        total_searches: 0,
        opportunity_breakdown: { high: 0, medium: 0, low: 0 },
        top_business_types: [],
        discovery_trend: []
      }
    end
  end
end
