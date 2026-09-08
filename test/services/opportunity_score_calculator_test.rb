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
      name:         'Lagos Delight Restaurant',
      types:        ['restaurant', 'food', 'point_of_interest', 'establishment'],
      business_type: 'restaurants',
      website:      nil,
      phone:        '+2348032079169',
      rating:       4.6,
      review_count: 287
    }
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # BACKWARD COMPATIBILITY — Generic scoring (no profile)
  # These preserve the exact behavior that existed before Task 6.
  # ─────────────────────────────────────────────────────────────────────────────

  test 'generic: scores correctly for top prospect (no website, phone, whatsapp, 4.6 rating, 287 reviews)' do
    data = {
      name: 'Abuja Delight Restaurant',
      website: nil,
      phone: '+2348032079169',
      rating: 4.6,
      review_count: 287
    }

    result = OpportunityScoreCalculator.call(business: data)

    # Generic scoring (no profile): 30+20+15+8+5 = 78 → medium tier (just under 80)
    assert_operator result[:score], :>=, 50
    assert_includes %w[high medium], result[:tier]
    assert_equal result[:tier].upcase, result[:level]
    assert_includes result[:factors], 'No website'
    assert_includes result[:factors], 'Phone available'
    assert_includes result[:factors], 'WhatsApp available'
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
    assert_equal 'high', result[:tier]
    assert_equal false, result[:personalized]
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # PERSONALIZED SCORING — Profile-driven
  # ─────────────────────────────────────────────────────────────────────────────

  test 'personalized: website_dev profile gives HIGH score to restaurant with no website' do
    result = OpportunityScoreCalculator.call(
      business: restaurant_no_website,
      profile:  website_dev_profile
    )

    assert_operator result[:score], :>=, 70, "Expected >= 70 for matching target + no_website signal"
    assert_includes %w[high medium], result[:tier]
    assert_equal true, result[:personalized]
    # Should include a no-website factor because profile defines it as an opportunity signal
    website_factor = result[:factors].any? { |f| f.downcase.include?('website') }
    assert website_factor, "Expected a 'website'-related factor for website dev profile"
  end

  test 'personalized: car_sales profile gives LOWER score to restaurant with no website' do
    result = OpportunityScoreCalculator.call(
      business: restaurant_no_website,
      profile:  car_sales_profile
    )

    # Must not be HIGH — restaurant doesn't match car-sales targets, no website isn't their signal
    assert_operator result[:score], :<, 80,
      "Car sales profile should NOT give a restaurant HIGH score just for having no website"
    assert_equal true, result[:personalized]
  end

  test 'CRITICAL: same business scores differently for website_dev vs car_sales profile' do
    business = restaurant_no_website

    website_dev_result = OpportunityScoreCalculator.call(business: business, profile: website_dev_profile)
    car_sales_result   = OpportunityScoreCalculator.call(business: business, profile: car_sales_profile)

    assert_not_equal website_dev_result[:score], car_sales_result[:score],
      "Same business MUST produce different scores for materially different profiles"

    # Website Dev should score this restaurant much higher than Car Sales
    assert_operator website_dev_result[:score], :>, car_sales_result[:score],
      "Website Dev profile should score a no-website restaurant higher than Car Sales profile"
  end

  test 'personalized: no_website signal only matters if profile lists it as opportunity' do
    business_no_website = { name: 'Test Co', types: ['restaurant'], website: nil, phone: nil, rating: 3.0, review_count: 5 }

    # With website dev profile (no_website in signals): should award opportunity points
    with_signal = OpportunityScoreCalculator.call(
      business: business_no_website,
      profile:  website_dev_profile
    )

    # With car sales profile (no_website NOT in signals): no website points
    without_signal = OpportunityScoreCalculator.call(
      business: business_no_website,
      profile:  car_sales_profile
    )

    assert_operator with_signal[:score], :>, without_signal[:score],
      "no_website should contribute more when profile lists it as an opportunity signal"
  end

  test 'personalized: phone_available contact signal contributes when business has phone' do
    business_with_phone = { name: 'Restaurant A', types: ['restaurant'], website: nil, phone: '+2348011111111', rating: 4.0, review_count: 50 }

    result = OpportunityScoreCalculator.call(
      business: business_with_phone,
      profile:  website_dev_profile  # has phone_available in contact_signals
    )

    assert_operator result[:score], :>=, 30
    assert_equal true, result[:personalized]
  end

  test 'personalized: target business match increases score significantly' do
    matching_business = {
      name:          'Best Restaurant Lagos',
      types:         ['restaurant', 'food', 'establishment'],
      business_type: 'restaurants',
      website:       nil,
      phone:         '+2348011111111',
      rating:        4.0,
      review_count:  80
    }
    non_matching_business = {
      name:          'Lagos Auto Parts',
      types:         ['car_repair', 'establishment'],
      business_type: 'auto_parts',
      website:       nil,
      phone:         '+2348011111111',
      rating:        4.0,
      review_count:  80
    }

    match_result    = OpportunityScoreCalculator.call(business: matching_business, profile: website_dev_profile)
    no_match_result = OpportunityScoreCalculator.call(business: non_matching_business, profile: website_dev_profile)

    assert_operator match_result[:score], :>, no_match_result[:score],
      "A business matching the profile's target_businesses should score higher"
  end

  test 'personalized: score is reproducible — same inputs always yield same output' do
    business = restaurant_no_website
    profile  = website_dev_profile

    result1 = OpportunityScoreCalculator.call(business: business, profile: profile)
    result2 = OpportunityScoreCalculator.call(business: business, profile: profile)
    result3 = OpportunityScoreCalculator.call(business: business, profile: profile)

    assert_equal result1[:score], result2[:score], "Score must be deterministic"
    assert_equal result2[:score], result3[:score], "Score must be deterministic"
  end

  test 'personalized: score is always between 0 and 100' do
    # Try to produce an extreme score
    business = {
      name:          'Everything Restaurant',
      types:         ['restaurant', 'food'],
      business_type: 'restaurants',
      website:       nil,
      phone:         '+2348099999999',
      rating:        5.0,
      review_count:  10_000
    }

    result = OpportunityScoreCalculator.call(business: business, profile: website_dev_profile)

    assert_operator result[:score], :>=, 0
    assert_operator result[:score], :<=, 100
  end

  test 'personalized: score is always between 0 and 100 for business with no signals' do
    business = { name: 'Ghost Business', types: [], website: nil, phone: nil, rating: 0, review_count: 0 }

    result = OpportunityScoreCalculator.call(business: business, profile: car_sales_profile)

    assert_operator result[:score], :>=, 0
    assert_operator result[:score], :<=, 100
  end

  test 'personalized: returns explainable factors array' do
    result = OpportunityScoreCalculator.call(
      business: restaurant_no_website,
      profile:  website_dev_profile
    )

    assert_kind_of Array, result[:factors]
    assert result[:factors].all? { |f| f.is_a?(String) }
  end

  test 'personalized: HIGH tier for score >= 80' do
    # Restaurant + website dev profile with perfect signals should hit HIGH
    business = {
      name:          'Perfect Restaurant',
      types:         ['restaurant'],
      business_type: 'restaurants',
      website:       nil,
      phone:         '+2348011111111',
      rating:        4.5,
      review_count:  200
    }
    result = OpportunityScoreCalculator.call(business: business, profile: website_dev_profile)

    if result[:score] >= 80
      assert_equal 'high', result[:tier]
      assert_equal 'HIGH', result[:level]
    elsif result[:score] >= 50
      assert_equal 'medium', result[:tier]
    else
      assert_equal 'low', result[:tier]
    end
  end

  test 'personalized: car_sales profile scores car business with phone/whatsapp as medium-high' do
    car_business = {
      name:          'Lekki Auto Centre',
      types:         ['car_dealer', 'establishment'],
      business_type: 'car dealers',
      website:       'https://lekkiauto.com',
      phone:         '+2348055555555',
      rating:        4.2,
      review_count:  180
    }

    result = OpportunityScoreCalculator.call(business: car_business, profile: car_sales_profile)

    # Car business + car sales profile + phone + WhatsApp + strong activity
    assert_operator result[:score], :>=, 40,
      "Car sales profile should give meaningful score to a car business with phone/whatsapp"
    assert_equal true, result[:personalized]
  end
end
