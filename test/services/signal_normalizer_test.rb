# test/services/signal_normalizer_test.rb

# frozen_string_literal: true

require 'test_helper'

class SignalNormalizerTest < ActiveSupport::TestCase
  # ──────────────────────────────────────────────────────────────
  # Opportunity signal normalization
  # ──────────────────────────────────────────────────────────────

  test 'normalizes exact lowercase no_website to :no_website' do
    result = SignalNormalizer.normalize_opportunity_signals(['no_website'])
    assert_includes result, :no_website
  end

  test 'normalizes "No website" (titlecase) to :no_website' do
    result = SignalNormalizer.normalize_opportunity_signals(['No website'])
    assert_includes result, :no_website
  end

  test 'normalizes "Outdated website" to :no_website' do
    result = SignalNormalizer.normalize_opportunity_signals(['Outdated website'])
    assert_includes result, :no_website
  end

  test 'normalizes "Businesses without a website" via substring match to :no_website' do
    result = SignalNormalizer.normalize_opportunity_signals(['Businesses without a website'])
    assert_includes result, :no_website
  end

  test 'normalizes "Poor online reviews" to :poor_reviews' do
    result = SignalNormalizer.normalize_opportunity_signals(['Poor online reviews'])
    assert_includes result, :poor_reviews
  end

  test 'normalizes "Low rating" to :poor_reviews' do
    result = SignalNormalizer.normalize_opportunity_signals(['Low rating'])
    assert_includes result, :poor_reviews
  end

  test 'normalizes "Strong customer activity" to :strong_activity' do
    result = SignalNormalizer.normalize_opportunity_signals(['Strong customer activity'])
    assert_includes result, :strong_activity
  end

  test 'normalizes "Phone available" in opportunity signals to :phone_available' do
    result = SignalNormalizer.normalize_opportunity_signals(['Phone available'])
    assert_includes result, :phone_available
  end

  test 'normalizes "WhatsApp available" in opportunity signals to :whatsapp_available' do
    result = SignalNormalizer.normalize_opportunity_signals(['WhatsApp available'])
    assert_includes result, :whatsapp_available
  end

  test 'deduplicates normalized codes when multiple inputs map to same code' do
    result = SignalNormalizer.normalize_opportunity_signals(['No website', 'Outdated website', 'no_website'])
    assert_equal 1, result.count(:no_website)
  end

  test 'ignores unknown/unrecognized opportunity signals gracefully' do
    result = SignalNormalizer.normalize_opportunity_signals(['Completely unknown signal XYZ'])
    assert_empty result
  end

  test 'handles empty array gracefully' do
    result = SignalNormalizer.normalize_opportunity_signals([])
    assert_empty result
  end

  test 'handles nil gracefully' do
    result = SignalNormalizer.normalize_opportunity_signals(nil)
    assert_empty result
  end

  test 'normalizes multiple signals correctly' do
    signals = ['No website', 'Phone available', 'WhatsApp available']
    result = SignalNormalizer.normalize_opportunity_signals(signals)
    assert_includes result, :no_website
    assert_includes result, :phone_available
    assert_includes result, :whatsapp_available
  end

  # ──────────────────────────────────────────────────────────────
  # Contact signal normalization
  # ──────────────────────────────────────────────────────────────

  test 'normalizes "Phone available" contact signal to :phone_available' do
    result = SignalNormalizer.normalize_contact_signals(['Phone available'])
    assert_includes result, :phone_available
  end

  test 'normalizes "WhatsApp available" contact signal to :whatsapp_available' do
    result = SignalNormalizer.normalize_contact_signals(['WhatsApp available'])
    assert_includes result, :whatsapp_available
  end

  test 'normalizes "WhatsApp reachable" to :whatsapp_available' do
    result = SignalNormalizer.normalize_contact_signals(['WhatsApp reachable'])
    assert_includes result, :whatsapp_available
  end

  test 'normalizes "Email available" contact signal to :email_available' do
    result = SignalNormalizer.normalize_contact_signals(['Email available'])
    assert_includes result, :email_available
  end

  test 'ignores unknown contact signals gracefully' do
    result = SignalNormalizer.normalize_contact_signals(['Carrier pigeon available'])
    assert_empty result
  end

  # ──────────────────────────────────────────────────────────────
  # Target businesses normalization
  # ──────────────────────────────────────────────────────────────

  test 'normalizes target businesses to downcased stripped strings' do
    result = SignalNormalizer.normalize_target_businesses(['Restaurants', '  Hotels  ', 'BARBERSHOPS'])
    assert_equal ['restaurants', 'hotels', 'barbershops'], result
  end

  test 'filters empty strings from target businesses' do
    result = SignalNormalizer.normalize_target_businesses(['Restaurants', '', '  '])
    assert_equal ['restaurants'], result
  end

  test 'handles nil target businesses' do
    result = SignalNormalizer.normalize_target_businesses(nil)
    assert_empty result
  end
end
