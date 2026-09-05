# app/services/opportunity_score_calculator.rb

# frozen_string_literal: true

class OpportunityScoreCalculator < ApplicationService
  def initialize(business_data)
    @business = business_data.with_indifferent_access
  end

  def call
    score = 0
    factors = []
    signals = []

    has_website = business[:website].present?
    phone = business[:phone] || business[:national_phone] || business[:phone_number] || business[:international_phone_number]
    has_phone = phone.present?
    
    # WhatsApp check based on phone availability & valid digits length
    has_whatsapp = false
    if has_phone
      digits = phone.to_s.gsub(/\D/, '')
      has_whatsapp = digits.length >= 7
    end

    rating = business[:rating].to_f
    review_count = (business[:review_count] || business[:user_rating_count] || 0).to_i

    # 1. WEBSITE OPPORTUNITY (+30 if no website)
    if !has_website
      score += 30
      factors << 'No website'
      signals << '🚨 No website (Direct digital opportunity)'
    else
      signals << '🌐 Website active'
    end

    # 2. PHONE AVAILABILITY (+20 if phone present)
    if has_phone
      score += 20
      factors << 'Phone available'
      signals << '📞 Direct phone line available'
    end

    # 3. WHATSAPP AVAILABILITY (+15 if WhatsApp available)
    if has_whatsapp
      score += 15
      factors << 'WhatsApp available'
      signals << '💬 WhatsApp reachable'
    end

    # 4. RATING SCORES
    if rating >= 4.5
      score += 15
      factors << "#{rating.round(1)} rating"
      signals << '⭐ High customer rating (4.5+)'
    elsif rating >= 4.0
      score += 12
      factors << "#{rating.round(1)} rating"
      signals << '⭐ Solid customer rating (4.0+)'
    elsif rating >= 3.5
      score += 8
      factors << "#{rating.round(1)} rating"
      signals << '⭐ Good customer rating (3.5+)'
    elsif rating >= 3.0
      score += 4
      factors << "#{rating.round(1)} rating"
      signals << '⭐ Moderate customer rating (3.0+)'
    end

    # 5. REVIEWS SCORES
    if review_count > 500
      score += 10
      factors << "#{review_count} reviews"
      signals << '🔥 Very high review volume (500+ reviews)'
    elsif review_count >= 101
      score += 7
      factors << "#{review_count} reviews"
      signals << '🔥 Strong review activity (101-500 reviews)'
    elsif review_count >= 51
      score += 4
      factors << "#{review_count} reviews"
      signals << '💬 Active reviews (51-100 reviews)'
    elsif review_count >= 11
      score += 2
      factors << "#{review_count} reviews"
      signals << '💬 Growing reviews (11-50 reviews)'
    end

    # Cap score at 100
    score = [score, 100].min

    tier = if score >= 80
             'high'
           elsif score >= 50
             'medium'
           else
             'low'
           end

    level = tier.upcase

    {
      score: score,
      tier: tier,
      level: level,
      factors: factors,
      signals: signals
    }
  end

  private

  attr_reader :business
end

