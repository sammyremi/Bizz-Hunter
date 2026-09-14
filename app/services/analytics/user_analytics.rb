# app/services/analytics/user_analytics.rb

# frozen_string_literal: true

module Analytics
  class UserAnalytics < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      return empty_analytics if user.blank?

      results_scope  = user.search_results
      searches_scope  = user.searches
      prospects_scope = user.prospects

      total_businesses_found = results_scope.count
      total_searches         = searches_scope.count
      saved_prospects_count  = prospects_scope.count

      tier_counts = results_scope.group(:opportunity_tier).count
      high_opp   = tier_counts['high'] || 0
      med_opp    = tier_counts['medium'] || 0
      low_opp    = tier_counts['low'] || 0

      high_opportunity_rate = if total_businesses_found > 0
                                (high_opp.to_f / total_businesses_found * 100).round(1)
                              else
                                0.0
                              end

      no_website_count  = results_scope.where("website IS NULL OR website = ''").count
      has_website_count = total_businesses_found - no_website_count

      phone_count    = results_scope.where("phone IS NOT NULL AND phone != '' OR national_phone IS NOT NULL AND national_phone != ''").count
      whatsapp_count = results_scope.where("phone IS NOT NULL AND phone != '' OR national_phone IS NOT NULL AND national_phone != ''").count

      # Top Business Types & Best Performing Targets
      types_count = Hash.new(0)
      types_score_sum = Hash.new(0)

      results_scope.pluck(:types, :business_type, :opportunity_score).each do |types_arr, main_type, score|
        clean = Array(types_arr).reject { |t| %w[point_of_interest establishment business].include?(t.to_s.downcase) }
        clean = [main_type || 'Business'] if clean.empty?
        clean.each do |t|
          human = t.to_s.tr('_', ' ').strip.titleize
          types_count[human]     += 1
          types_score_sum[human] += score.to_i
        end
      end

      top_types = types_count.map { |type, count| { 'type' => type, 'count' => count } }
                              .sort_by { |item| -item['count'] }
                              .first(5)

      best_performing = types_count.map do |type, count|
        avg = (types_score_sum[type].to_f / count).round(1)
        { 'type' => type, 'avg_score' => avg, 'count' => count }
      end.sort_by { |item| [-item['avg_score'], -item['count'], item['type']] }.first(5)

      # Discovery trend by date
      trend_hash = results_scope.group("DATE(created_at)").count
      discovery_trend = trend_hash.map { |date, count| { 'date' => date.to_s, 'count' => count } }
                                 .sort_by { |item| item['date'] }

      # Prospecting Profile Performance Breakdown
      profiles_data = user.prospecting_profiles.map do |profile|
        prof_searches   = profile.searches.count
        prof_businesses = profile.search_results.count
        prof_high_opp   = profile.search_results.where(opportunity_tier: 'high').count
        prof_rate       = prof_businesses > 0 ? (prof_high_opp.to_f / prof_businesses * 100).round(1) : 0.0

        {
          id:                    profile.id,
          name:                  profile.name,
          service:               profile.service,
          searches_count:        prof_searches,
          businesses_found:      prof_businesses,
          high_opportunity_count: prof_high_opp,
          high_opportunity_rate:  prof_rate
        }
      end

      {
        businesses_found:        total_businesses_found,
        high_opportunity:        high_opp,
        medium_opportunity:      med_opp,
        low_opportunity:         low_opp,
        high_opportunity_rate:   high_opportunity_rate,
        no_website:              no_website_count,
        website_available:       has_website_count,
        phone_available:         phone_count,
        whatsapp_available:      whatsapp_count,
        saved_prospects:         saved_prospects_count,
        total_searches:          total_searches,
        opportunity_breakdown:   { high: high_opp, medium: med_opp, low: low_opp },
        top_business_types:      top_types,
        best_performing_targets: best_performing,
        profiles:                profiles_data,
        discovery_trend:         discovery_trend
      }
    end

    private

    attr_reader :user

    def empty_analytics
      {
        businesses_found:        0,
        high_opportunity:        0,
        medium_opportunity:      0,
        low_opportunity:         0,
        high_opportunity_rate:   0.0,
        no_website:              0,
        website_available:       0,
        phone_available:         0,
        whatsapp_available:      0,
        saved_prospects:         0,
        total_searches:          0,
        opportunity_breakdown:   { high: 0, medium: 0, low: 0 },
        top_business_types:      [],
        best_performing_targets: [],
        profiles:                [],
        discovery_trend:         []
      }
    end
  end
end
