# app/services/opportunity_score_calculator.rb

# frozen_string_literal: true

class OpportunityScoreCalculator < ApplicationService
  def initialize(business_data)
    @business = business_data.with_indifferent_access
  end

  def call
    score = 0
    signals = []

    has_website = business[:website].present?
    phone = business[:phone] || business[:national_phone] || business[:phone_number]
    has_phone = phone.present?
    rating = business[:rating].to_f
    review_count = business[:review_count].to_i

    if !has_website
      score += 30
      signals << '🚨 No website (Direct digital opportunity)'
    else
      signals << '🌐 Website active'
    end

    if rating >= 4.5
      score += 25
      signals << '⭐ High customer rating (4.5+)'
    elsif rating >= 4.0
      score += 15
      signals << '⭐ Solid customer rating (4.0+)'
    end

    if review_count >= 100
      score += 20
      signals << '🔥 Strong review activity (100+ reviews)'
    elsif review_count >= 20
      score += 10
      signals << '💬 Active reviews (20+ reviews)'
    end

    if has_phone
      score += 25
      signals << '📞 Direct phone line available'
    end

    level = if score >= 70
              'HIGH'
            elsif score >= 45
              'MEDIUM'
            else
              'STANDARD'
            end

    {
      score: score,
      level: level,
      signals: signals
    }
  end

  private

  attr_reader :business
end
