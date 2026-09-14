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
# IMPORTANT DESIGN CONSTRAINTS
# ─────────────────────────────
# * Missing data ≠ confirmed negative.
#   If Google Places did not return a website field, we treat it as "unknown",
#   but the existing pipeline sets website = nil when Google Places confirms no website.
#   Do not invent facts.
#
# * phone_available ≠ WhatsApp verified.
#   A phone number proves only that a phone number exists. WhatsApp availability
#   is inferred/possible — not confirmed. Factors reflect this distinction.
#
# * no_online_booking must NOT be inferred from no_website.
#   A business without a website may use Google booking, Facebook, Instagram,
#   third-party platforms, or WhatsApp booking.
#
# Usage:
#   OpportunityScoreCalculator.call(business: data)                  # generic
#   OpportunityScoreCalculator.call(business: data, profile: profile) # personalized
class OpportunityScoreCalculator < ApplicationService
  # Tier thresholds — centralized so nothing else needs to know the numbers
  HIGH_THRESHOLD   = 80
  MEDIUM_THRESHOLD = 50

  # Section point caps for profile-aware scoring
  RELEVANCE_MAX   = 40  # Relevance is the primary differentiator
  OPPORTUNITY_MAX = 35
  CONTACT_MAX     = 15
  ACTIVITY_MAX    = 10  # Supporting signal only

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

    # 4. Activity / Quality — rating + review volume (supporting signal only)
    activity_pts, activity_factors = score_activity

    factors = relevance_factors + opportunity_factors + contact_factors + activity_factors

    raw_score = relevance_pts + opportunity_pts + contact_pts + activity_pts
    score = clamp(raw_score)
    tier  = determine_tier(score)

    build_result(score, tier, factors, personalized: true)
  end

  # 1. Relevance: does business type match profile's target_businesses?
  #
  # Strategy: normalize both sides to singular downcased tokens, then compare.
  # Handles "restaurant" ↔ "restaurants", "car dealer" ↔ "car dealers" etc.
  # Uses word boundary matching so "car" doesn't match "care home".
  def score_relevance(target_list)
    return [0, ["Business type does not match your target"]] if target_list.empty?

    business_types = extract_business_types  # downcased, underscores→spaces, noise removed

    target_stems = target_list.map { |t| stem(t) }
    business_stems = business_types.map { |bt| stem(bt) }

    strong_match = target_stems.any? do |ts|
      business_stems.any? { |bs| target_matches_business_type?(ts, bs) }
    end

    if strong_match
      label = "Matches your target: #{profile.target_businesses.first}"
      return [RELEVANCE_MAX, [label]]
    end

    # Partial match: the search-level business_type param (e.g. "restaurants") vs profile targets
    search_type_stem = stem(business.fetch(:business_type, '').to_s)
    if search_type_stem.present?
      partial = target_stems.any? { |ts| target_matches_business_type?(ts, search_type_stem) }
      if partial
        return [20, ["Partially matches your target businesses"]]
      end
    end

    [0, ["Business type does not match your target"]]
  end

  def target_matches_business_type?(target_stem, business_stem)
    return false if target_stem.blank? || business_stem.blank?
    return true if target_stem == business_stem

    pattern = /\b#{Regexp.escape(target_stem)}\b/
    return true if business_stem.match?(pattern)

    pattern_rev = /\b#{Regexp.escape(business_stem)}\b/
    return true if target_stem.match?(pattern_rev)

    false
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
      # Treat nil/blank website as confirmed no-website (the pipeline sets nil when Google
      # Places returns no websiteUri — this is reliable for the current data source).
      match = business[:website].blank?
      [match, "No website detected", 25]

    when :poor_reviews
      rating = business[:rating].to_f
      # Only score when we have an actual rating (0 means unknown/no rating)
      match = rating > 0 && rating < 3.5
      [match, "Below-average reviews (improvement opportunity)", 15]

    when :no_online_booking
      # We do NOT infer no_online_booking from no_website.
      # Without factual booking data, this signal cannot be scored.
      [false, nil, 0]

    when :strong_activity
      review_count = (business[:review_count] || 0).to_i
      match = review_count > 100
      [match, "Strong customer activity (#{review_count} reviews)", 15]

    when :relevant_business
      # Handled by score_relevance
      match = extract_business_types.any?
      [match, "Business type is relevant to your service", 8]

    when :phone_available
      match = extract_phone.present?
      [match, "Phone number available", 10]

    when :whatsapp_available
      # WhatsApp availability is INFERRED from phone presence — not verified.
      match = extract_phone.present?
      [match, "Phone present (WhatsApp likely possible)", 8]

    when :email_available
      match = business[:website].present?
      [match, "Website available for digital contact", 5]

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
        # Inferred from phone — label is honest
        if extract_phone.present?
          pts += 8
          factors << "Phone present (WhatsApp likely possible)"
        end
      when :email_available
        if business[:website].present?
          pts += 5
          factors << "Website available for digital contact"
        end
      end
    end

    factors.uniq!
    [clamp_section(pts, CONTACT_MAX), factors]
  end

  # 4. Activity signals: rating and review volume (supporting signal — max 10 pts)
  def score_activity
    pts     = 0
    factors = []

    rating       = business[:rating].to_f
    review_count = (business[:review_count] || 0).to_i

    # Rating (max 6 pts)
    rating_pts, rating_label = score_rating(rating)
    if rating_pts > 0
      pts += rating_pts
      factors << rating_label
    end

    # Review volume (max 4 pts)
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

    has_website = business[:website].present?
    phone       = extract_phone
    has_phone   = phone.present?

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

      # WhatsApp is inferred — phone presence makes it likely, not confirmed
      score   += 10
      factors << 'Phone present (WhatsApp likely possible)'
      signals << '💬 Phone present — WhatsApp contact may be possible'
    end

    # 3. Rating
    rating_pts, rating_label = score_rating(rating)
    if rating_pts > 0
      score += rating_pts
      factors << "#{rating.round(1)} rating"
      signals << rating_label
    end

    # 4. Review volume
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
      [6, '⭐ High customer rating (4.5+)']
    elsif rating >= 4.0
      [4, '⭐ Solid customer rating (4.0+)']
    elsif rating >= 3.5
      [2, '⭐ Good customer rating (3.5+)']
    elsif rating >= 3.0
      [1, '⭐ Moderate customer rating (3.0+)']
    else
      [0, nil]
    end
  end

  def score_reviews(review_count)
    if review_count > 500
      [4, '🔥 Very high review volume (500+ reviews)']
    elsif review_count >= 101
      [3, '🔥 Strong review activity (101–500 reviews)']
    elsif review_count >= 51
      [2, '💬 Active reviews (51–100 reviews)']
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

  # Returns downcased, space-normalized business type strings with noise words removed.
  def extract_business_types
    noise = %w[point_of_interest establishment business]
    Array(business[:types])
      .map { |t| t.to_s.downcase.tr('_', ' ').strip }
      .reject { |t| noise.include?(t) || t.empty? }
  end

  def stem(str)
    s = str.to_s.downcase.strip.gsub(/[_\-]/, ' ').squeeze(' ')
    return '' if s.empty?

    words = s.split(' ')
    words.map! do |w|
      if w.end_with?('ies') && w.length > 4
        w.sub(/ies$/, 'y')
      elsif w.end_with?('es') && w.length > 4 && !w.end_with?('sses')
        w.sub(/es$/, '')
      elsif w.end_with?('s') && w.length > 3 && !w.end_with?('ss')
        w.sub(/s$/, '')
      else
        w
      end
    end
    words.join(' ')
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
