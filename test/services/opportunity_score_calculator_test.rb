# test/services/opportunity_score_calculator_test.rb

# frozen_string_literal: true

require 'test_helper'
require 'ostruct'

class OpportunityScoreCalculatorTest < ActiveSupport::TestCase
  # ─────────────────────────────────────────────────────────────────────────────
  # Helpers
  # ─────────────────────────────────────────────────────────────────────────────

  def website_dev_profile
    build_profile(
      service:              'Website Development',
      target_businesses:    ['Restaurants'],
      opportunity_signals:  ['No website', 'Outdated website'],
      contact_signals:      ['Phone available', 'WhatsApp available']
    )
  end

  def car_sales_profile
    build_profile(
      service:              'Car Sales',
      target_businesses:    ['Car dealers', 'Auto parts'],
      opportunity_signals:  ['Phone available', 'WhatsApp available', 'Strong customer activity'],
      contact_signals:      ['Phone available', 'WhatsApp available']
    )
  end

  def build_profile(service:, target_businesses:, opportunity_signals:, contact_signals:)
    OpenStruct.new(
      service:             service,
      target_businesses:   target_businesses,
      opportunity_signals: opportunity_signals,
      contact_signals:     contact_signals
    )
  end

  # A restaurant with no website — the ideal Website Dev prospect
  def restaurant_no_website
    {
      name:          'Lagos Delight Restaurant',
      types:         ['restaurant', 'food', 'point_of_interest', 'establishment'],
      business_type: 'restaurants',
      website:       nil,
      phone:         '+2348032079169',
      rating:        4.6,
      review_count:  287
    }
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # BACKWARD COMPATIBILITY — Generic scoring (no profile)
  # ─────────────────────────────────────────────────────────────────────────────

  test 'generic: scores correctly for prospect without profile' do
    data = {
      name: 'Abuja Delight Restaurant',
      website: nil,
      phone: '+2348032079169',
      rating: 4.6,
      review_count: 287
    }

    result = OpportunityScoreCalculator.call(business: data)

    # Generic scoring (no profile): 30+20+10+6+3 = 69 → medium tier
    assert_operator result[:score], :>=, 50
    assert_equal 'medium', result[:tier]
    assert_equal 'MEDIUM', result[:level]
    assert_includes result[:factors], 'No website'
    assert_includes result[:factors], 'Phone available'
    assert_includes result[:factors], 'Phone present (WhatsApp likely possible)'
    assert_equal false, result[:personalized]
  end

  test 'generic: scores low for business with website, no phone, low rating' do
    data = {
      name: 'Established Tech Ltd',
      website: 'https://example.com',
      phone: nil,
      rating: 2.5,
      review_count: 5
    }

    result = OpportunityScoreCalculator.call(business: data)

    assert_equal 0, result[:score]
    assert_equal 'low', result[:tier]
    assert_equal 'LOW', result[:level]
    assert_empty result[:factors]
    assert_equal false, result[:personalized]
  end

  test 'generic: caps score at 100 maximum' do
    data = {
      name: 'Super High Opportunity',
      website: nil,
      phone: '+2348012345678',
      rating: 4.9,
      review_count: 600
    }

    result = OpportunityScoreCalculator.call(business: data)

    assert_operator result[:score], :<=, 100
    assert_equal false, result[:personalized]
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # TASK 6 REFINEMENT REQUIRED TESTS (Tests 1–10)
  # ─────────────────────────────────────────────────────────────────────────────

  test 'Test 1 — Target match: relevance > 0 for restaurant + restaurant-targeted profile' do
    result = OpportunityScoreCalculator.call(
      business: restaurant_no_website,
      profile:  website_dev_profile
    )

    relevance_factor = result[:factors].any? { |f| f.downcase.include?('matches your target') }
    assert relevance_factor, "Expected a target match factor for restaurant matching Website Dev profile"
    assert_operator result[:score], :>=, 40
  end

  test 'Test 2 — Target mismatch: relevance = 0 for restaurant + car-dealership profile' do
    result = OpportunityScoreCalculator.call(
      business: restaurant_no_website,
      profile:  car_sales_profile
    )

    mismatch_factor = result[:factors].any? { |f| f.downcase.include?('does not match your target') }
    assert mismatch_factor, "Expected target mismatch factor when restaurant evaluated by car sales profile"
  end

  test 'Test 3 — No website: strong opportunity contribution for website-dev profile' do
    result = OpportunityScoreCalculator.call(
      business: restaurant_no_website,
      profile:  website_dev_profile
    )

    no_web_factor = result[:factors].any? { |f| f.downcase.include?('no website detected') }
    assert no_web_factor, "Expected 'No website detected' opportunity factor for website dev profile"
  end

  test 'Test 4 — Same business, different profiles: same business produces different scores and reasons' do
    business = restaurant_no_website

    web_result = OpportunityScoreCalculator.call(business: business, profile: website_dev_profile)
    car_result = OpportunityScoreCalculator.call(business: business, profile: car_sales_profile)

    assert_not_equal web_result[:score], car_result[:score],
      "Same business MUST produce different scores for materially different profiles"
    assert_not_equal web_result[:factors], car_result[:factors],
      "Same business MUST produce different factors/reasons for different profiles"

    assert_operator web_result[:score], :>, car_result[:score],
      "Website Dev profile should score a no-website restaurant higher than Car Sales profile"
  end

  test 'Test 5 — Strong web-development prospect: restaurant with no website, phone, 500+ reviews, 4.8 rating => HIGH' do
    strong_prospect = {
      name:          'Lagos Grand Restaurant',
      types:         ['restaurant', 'food'],
      business_type: 'restaurants',
      website:       nil,
      phone:         '+2348032079169',
      rating:        4.8,
      review_count:  520
    }

    result = OpportunityScoreCalculator.call(
      business: strong_prospect,
      profile:  website_dev_profile
    )

    assert_equal 'high', result[:tier], "Strong prospect must fall into HIGH tier"
    assert_equal 'HIGH', result[:level]
    assert_operator result[:score], :>=, 80
  end

  test 'Test 6 — No website alone: poorly matched/weak business with no website does not automatically become HIGH' do
    weak_business = {
      name:          'Unknown Co',
      types:         ['lawyer'],
      business_type: 'lawyers',
      website:       nil,
      phone:         nil,
      rating:        0,
      review_count:  2
    }

    result = OpportunityScoreCalculator.call(
      business: weak_business,
      profile:  website_dev_profile # targets Restaurants
    )

    assert_not_equal 'high', result[:tier], "No website alone on an irrelevant business must NOT guarantee HIGH"
    assert_operator result[:score], :<, 50
  end

  test 'Test 7 — Unknown website: website presence prevents no_website opportunity signal' do
    business_with_website = {
      name:          'Tech Restaurant',
      types:         ['restaurant'],
      business_type: 'restaurants',
      website:       'https://techrestaurant.com',
      phone:         '+2348011111111',
      rating:        4.0,
      review_count:  50
    }

    result = OpportunityScoreCalculator.call(
      business: business_with_website,
      profile:  website_dev_profile
    )

    no_web_factor = result[:factors].any? { |f| f.downcase.include?('no website detected') }
    refute no_web_factor, "Website presence must NOT trigger no_website opportunity factor"
  end

  test 'Test 8 — WhatsApp: phone availability is treated as inferred proxy signal, not verified' do
    result = OpportunityScoreCalculator.call(
      business: restaurant_no_website,
      profile:  website_dev_profile
    )

    whatsapp_factors = result[:factors].select { |f| f.downcase.include?('whatsapp') }
    assert_equal 1, whatsapp_factors.size
    assert_includes whatsapp_factors.first, 'WhatsApp likely possible',
      "WhatsApp factor must represent availability as inferred/possible, not confirmed"
  end

  test 'Test 9 — Booking: no website does not automatically produce a no_online_booking score' do
    booking_profile = build_profile(
      service:              'Booking Software',
      target_businesses:    ['Restaurants'],
      opportunity_signals:  ['No online booking'],
      contact_signals:      ['Phone available']
    )

    result = OpportunityScoreCalculator.call(
      business: restaurant_no_website,
      profile:  booking_profile
    )

    booking_factor = result[:factors].any? { |f| f.downcase.include?('booking') }
    refute booking_factor, "Missing website must NOT award no_online_booking factor without factual booking data"
  end

  test 'Test 10 — Deterministic: same business + profile always produces same score and reasons' do
    business = restaurant_no_website
    profile  = website_dev_profile

    result1 = OpportunityScoreCalculator.call(business: business, profile: profile)
    result2 = OpportunityScoreCalculator.call(business: business, profile: profile)
    result3 = OpportunityScoreCalculator.call(business: business, profile: profile)

    assert_equal result1[:score], result2[:score]
    assert_equal result1[:tier], result2[:tier]
    assert_equal result1[:factors], result2[:factors]
  end
end
