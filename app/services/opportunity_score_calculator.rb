# app/services/opportunity_score_calculator.rb

# frozen_string_literal: true

# OpportunityScoreCalculator determines how valuable a discovered business is as a
# prospect for the user's selected service.
#
# With a profile:  Personalized scoring — profile signals determine which business
#                  attributes matter and how strongly.
# Without profile: Generic scoring — backward-compatible with existing behavior.
#
# Score range: 0–100
# Tiers: HIGH (80–100), MEDIUM (50–79), LOW (0–49)
#
# Usage:
#   OpportunityScoreCalculator.call(business: data)                  # generic
#   OpportunityScoreCalculator.call(business: data, profile: profile) # personalized
class OpportunityScoreCalculator < ApplicationService
  # Tier thresholds — centralized so nothing else needs to know the numbers
  HIGH_THRESHOLD   = 80
  MEDIUM_THRESHOLD = 50

  # Section point caps for profile-aware scoring
  RELEVANCE_MAX   = 35
  OPPORTUNITY_MAX = 35
  CONTACT_MAX     = 15
  ACTIVITY_MAX    = 15

  def initialize(business:, profile: nil)
    @business = business.with_indifferent_access
    @profile  = profile
  end

  def call
    if profile.present?
      personalized_score
    else
      generic_score
    end
  end

  private

  attr_reader :business, :profile

  # ─────────────────────────────────────────────────────────────────
  # PERSONALIZED SCORING (profile present)
  # ─────────────────────────────────────────────────────────────────

  def personalized_score
    factors = []

    # Resolve profile signals once
    opp_codes     = SignalNormalizer.normalize_opportunity_signals(profile.opportunity_signals)
    contact_codes = SignalNormalizer.normalize_contact_signals(profile.contact_signals)
    target_list   = SignalNormalizer.normalize_target_businesses(profile.target_businesses)

    # 1. Profile Relevance — is this the right type of business?
    relevance_pts, relevance_factors = score_relevance(target_list)

    # 2. Opportunity Signals — does the business have what the profile cares about?
    opportunity_pts, opportunity_factors = score_opportunity_signals(opp_codes)

    # 3. Contact Signals — can the user actually reach this business?
    contact_pts, contact_factors = score_contact_signals(contact_codes)

    # 4. Activity / Quality — rating + review volume (kept deliberately modest)
    activity_pts, activity_factors = score_activity

    factors.concat(relevance_factors)
           .concat(opportunity_factors)
           .concat(contact_factors)
           .concat(activity_factors)

    raw_score = relevance_pts + opportunity_pts + contact_pts + activity_pts
    score = clamp(raw_score)
    tier  = determine_tier(score)

    build_result(score, tier, factors, personalized: true)
  end

  # 1. Relevance: does business type match profile's target_businesses?
  def score_relevance(target_list)
    return [0, []] if target_list.empty?

    business_types = extract_business_types

    # Strong match: one of the target keywords appears in the business type strings
    strong_match = target_list.any? do |target|
      business_types.any? { |bt| bt.include?(target) || target.include?(bt) }
    end

    if strong_match
      label = "Matches your target: #{profile.target_businesses.first}"
      [RELEVANCE_MAX, [label]]
    else
      # Partial: check search-level business_type against profile targets
      # Only attempt when search_type is non-blank to avoid false positives
      search_type = business.fetch(:business_type, '').to_s.downcase.strip
      partial_match = search_type.present? && target_list.any? do |t|
        search_type.include?(t) || t.include?(search_type)
      end
      partial_match ? [20, ["Partially matches your target businesses"]] : [0, []]
    end
  end

  # 2. Opportunity signals: each matching signal earns points (section capped)
  def score_opportunity_signals(opp_codes)
    return [0, []] if opp_codes.empty?

    pts     = 0
    factors = []

    opp_codes.each do |code|
      match, label, points = check_opportunity_signal(code)
      if match
        pts += points
        factors << label
      end
    end

    [clamp_section(pts, OPPORTUNITY_MAX), factors]
  end

  def check_opportunity_signal(code)
    case code
    when :no_website
      match = business[:website].blank?
      [match, "No website (your profile targets this)", 25]
    when :poor_reviews
      rating = business[:rating].to_f
      match = rating > 0 && rating < 3.5
      [match, "Poor reviews (improvement opportunity)", 15]
    when :no_online_booking
      # Proxy: no website means no online booking system
      match = business[:website].blank?
      [match, "No online booking system", 10]
    when :strong_activity
      review_count = (business[:review_count] || 0).to_i
      match = review_count > 100
      [match, "Strong customer activity (#{review_count} reviews)", 15]
    when :relevant_business
      # Already handled by relevance section; award modest bonus if here too
      [true, "Business type relevant to your service", 10]
    when :phone_available
      match = extract_phone.present?
      [match, "Phone contact available", 10]
    when :whatsapp_available
      match = whatsapp_available?
      [match, "WhatsApp reachable", 10]
    when :email_available
      match = business[:website].present?
      [match, "Digital contact available (website)", 5]
    else
      [false, nil, 0]
    end
  end

  # 3. Contact signals: can the user reach this business?
  def score_contact_signals(contact_codes)
    return [0, []] if contact_codes.empty?

    pts     = 0
    factors = []

    contact_codes.each do |code|
      case code
      when :phone_available
        if extract_phone.present?
          pts += 10
          factors << "Phone number available"
        end
      when :whatsapp_available
        if whatsapp_available?
          pts += 10
          factors << "WhatsApp reachable"
        end
      when :email_available
        if business[:website].present?
          pts += 5
          factors << "Online contact available"
        end
      end
    end

    # Deduplicate factors that overlap with opportunity section
    factors.uniq!
    [clamp_section(pts, CONTACT_MAX), factors]
  end

  # 4. Activity signals: rating and review volume (kept moderate — max 15 pts)
  def score_activity
    pts     = 0
    factors = []

    rating       = business[:rating].to_f
    review_count = (business[:review_count] || 0).to_i

    # Rating (max 8 pts)
    rating_pts, rating_label = score_rating(rating)
    if rating_pts > 0
      pts += rating_pts
      factors << rating_label
    end

    # Review volume (max 7 pts)
    review_pts, review_label = score_reviews(review_count)
    if review_pts > 0
      pts += review_pts
      factors << review_label
    end

    [clamp_section(pts, ACTIVITY_MAX), factors]
  end

  # ─────────────────────────────────────────────────────────────────
  # GENERIC SCORING (no profile — backward compatible)
  # ─────────────────────────────────────────────────────────────────

  def generic_score
    score   = 0
    factors = []
    signals = []

    has_website  = business[:website].present?
    phone        = extract_phone
    has_phone    = phone.present?
    has_whatsapp = whatsapp_available?

    rating       = business[:rating].to_f
    review_count = (business[:review_count] || business[:user_rating_count] || 0).to_i

    # 1. Website opportunity (+30 if no website)
    if !has_website
      score += 30
      factors << 'No website'
      signals << '🚨 No website (Direct digital opportunity)'
    else
      signals << '🌐 Website active'
    end

    # 2. Phone availability (+20)
    if has_phone
      score += 20
      factors << 'Phone available'
      signals << '📞 Direct phone line available'
    end

    # 3. WhatsApp availability (+15)
    if has_whatsapp
      score += 15
      factors << 'WhatsApp available'
      signals << '💬 WhatsApp reachable'
    end

    # 4. Rating
    rating_pts, rating_label = score_rating(rating)
    if rating_pts > 0
      score += rating_pts
      factors << "#{rating.round(1)} rating"
      signals << rating_label
    end

    # 5. Review volume
    review_pts, review_label = score_reviews(review_count)
    if review_pts > 0
      score += review_pts
      factors << "#{review_count} reviews"
      signals << review_label
    end

    score = clamp(score)
    tier  = determine_tier(score)

    build_result(score, tier, factors, personalized: false, signals: signals)
  end

  # ─────────────────────────────────────────────────────────────────
  # SHARED HELPERS
  # ─────────────────────────────────────────────────────────────────

  def score_rating(rating)
    if rating >= 4.5
      [8, '⭐ High customer rating (4.5+)']
    elsif rating >= 4.0
      [5, '⭐ Solid customer rating (4.0+)']
    elsif rating >= 3.5
      [3, '⭐ Good customer rating (3.5+)']
    elsif rating >= 3.0
      [1, '⭐ Moderate customer rating (3.0+)']
    else
      [0, nil]
    end
  end

  def score_reviews(review_count)
    if review_count > 500
      [7, '🔥 Very high review volume (500+ reviews)']
    elsif review_count >= 101
      [5, '🔥 Strong review activity (101–500 reviews)']
    elsif review_count >= 51
      [3, '💬 Active reviews (51–100 reviews)']
    elsif review_count >= 11
      [1, '💬 Growing reviews (11–50 reviews)']
    else
      [0, nil]
    end
  end

  def extract_phone
    business[:phone] ||
      business[:national_phone] ||
      business[:phone_number] ||
      business[:international_phone_number]
  end

  def whatsapp_available?
    phone = extract_phone
    return false if phone.blank?

    phone.to_s.gsub(/\D/, '').length >= 7
  end

  def extract_business_types
    raw = Array(business[:types]).map { |t| t.to_s.downcase.tr('_', ' ').strip }
    raw.reject { |t| %w[point_of_interest establishment business food].include?(t) }
  end

  def clamp(score)
    [[score, 0].max, 100].min
  end

  def clamp_section(pts, max)
    [[pts, 0].max, max].min
  end

  def determine_tier(score)
    if score >= HIGH_THRESHOLD
      'high'
    elsif score >= MEDIUM_THRESHOLD
      'medium'
    else
      'low'
    end
  end

  def build_result(score, tier, factors, personalized:, signals: nil)
    result = {
      score:        score,
      tier:         tier,
      level:        tier.upcase,
      factors:      factors.compact.uniq,
      personalized: personalized
    }
    result[:signals] = signals if signals
    result
  end
end
