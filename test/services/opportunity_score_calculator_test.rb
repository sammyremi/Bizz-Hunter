# test/services/opportunity_score_calculator_test.rb

# frozen_string_literal: true

require 'test_helper'

class OpportunityScoreCalculatorTest < ActiveSupport::TestCase
  test 'calculates score correctly for top prospect (no website, phone, whatsapp, 4.6 rating, 287 reviews)' do
    data = {
      name: 'Abuja Delight Restaurant',
      website: nil,
      phone: '+2348032079169',
      rating: 4.6,
      review_count: 287
    }

    result = OpportunityScoreCalculator.call(data)

    # 30 (no website) + 20 (phone) + 15 (whatsapp) + 15 (4.6 rating) + 7 (101-500 reviews) = 87
    assert_equal 87, result[:score]
    assert_equal 'high', result[:tier]
    assert_equal 'HIGH', result[:level]
    assert_includes result[:factors], 'No website'
    assert_includes result[:factors], 'Phone available'
    assert_includes result[:factors], 'WhatsApp available'
    assert_includes result[:factors], '4.6 rating'
    assert_includes result[:factors], '287 reviews'
  end

  test 'calculates tier low for low scoring business' do
    data = {
      name: 'Established Tech Ltd',
      website: 'https://example.com',
      phone: nil,
      rating: 2.5,
      review_count: 5
    }

    result = OpportunityScoreCalculator.call(data)

    assert_equal 0, result[:score]
    assert_equal 'low', result[:tier]
    assert_equal 'LOW', result[:level]
    assert_empty result[:factors]
  end

  test 'caps score at 100 max' do
    data = {
      name: 'Super High Opportunity',
      website: nil,
      phone: '+2348012345678',
      rating: 4.9,
      review_count: 600
    }

    result = OpportunityScoreCalculator.call(data)

    # 30 + 20 + 15 + 15 + 10 = 90
    assert_operator result[:score], :<=, 100
    assert_equal 'high', result[:tier]
  end
end
