# app/services/signal_normalizer.rb

# frozen_string_literal: true

# SignalNormalizer maps human-readable profile signal strings (as produced by the
# Gemini Profile Builder or entered by users) to internal symbol codes used by
# OpportunityScoreCalculator.
#
# Gemini may produce strings like:
#   "No website", "no_website", "Businesses without a website", "Outdated website"
# All of these should resolve to the internal code :no_website.
#
# To add support for a new signal: add an entry to OPPORTUNITY_MAP or CONTACT_MAP.
class SignalNormalizer
  # Maps normalized (downcased, stripped) substrings → internal code
  # Order matters: more specific patterns should come first.
  OPPORTUNITY_MAP = {
    # No/outdated website
    'no website'          => :no_website,
    'no_website'          => :no_website,
    'without a website'   => :no_website,
    'without website'     => :no_website,
    'outdated website'    => :no_website,
    'outdated_website'    => :no_website,
    'lacks a website'     => :no_website,
    'lacks website'       => :no_website,
    'missing website'     => :no_website,

    # Poor reviews / low rating
    'poor online reviews' => :poor_reviews,
    'poor reviews'        => :poor_reviews,
    'negative reviews'    => :poor_reviews,
    'low rating'          => :poor_reviews,
    'low_rating'          => :poor_reviews,
    'bad reviews'         => :poor_reviews,

    # No online booking
    'no online booking'   => :no_online_booking,
    'no booking system'   => :no_online_booking,
    'no_online_booking'   => :no_online_booking,
    'no booking'          => :no_online_booking,

    # Relevant business / strong activity
    'relevant business'   => :relevant_business,
    'relevant_business'   => :relevant_business,
    'strong customer activity' => :strong_activity,
    'high review volume'  => :strong_activity,
    'strong_activity'     => :strong_activity,
    'high customer activity' => :strong_activity,
    'active customer base' => :strong_activity,

    # Contact as opportunity
    'phone available'     => :phone_available,
    'phone_available'     => :phone_available,
    'whatsapp available'  => :whatsapp_available,
    'whatsapp_available'  => :whatsapp_available,
    'email available'     => :email_available,
    'email_available'     => :email_available
  }.freeze

  CONTACT_MAP = {
    'phone available'     => :phone_available,
    'phone_available'     => :phone_available,
    'whatsapp available'  => :whatsapp_available,
    'whatsapp_available'  => :whatsapp_available,
    'whatsapp reachable'  => :whatsapp_available,
    'email available'     => :email_available,
    'email_available'     => :email_available,
    'email contact'       => :email_available
  }.freeze

  # Normalize an array of opportunity signal strings → array of internal symbol codes
  # Unknown signals are silently ignored (returns only codes we understand).
  def self.normalize_opportunity_signals(signals)
    normalize_signals(Array(signals), OPPORTUNITY_MAP)
  end

  # Normalize an array of contact signal strings → array of internal symbol codes
  def self.normalize_contact_signals(signals)
    normalize_signals(Array(signals), CONTACT_MAP)
  end

  # Normalize an array of target_businesses strings → downcased, stripped strings
  # for substring matching against business types
  def self.normalize_target_businesses(targets)
    Array(targets).map { |t| t.to_s.strip.downcase }.reject(&:empty?)
  end

  private_class_method def self.normalize_signals(raw_signals, map)
    codes = []
    raw_signals.each do |signal|
      normalized = signal.to_s.strip.downcase
      next if normalized.empty?

      # First try exact key match
      code = map[normalized]
      unless code
        # Try substring match — find first map key that appears in the signal string
        code = map.find { |key, _| normalized.include?(key) }&.last
      end
      codes << code if code
    end
    codes.uniq
  end
end
