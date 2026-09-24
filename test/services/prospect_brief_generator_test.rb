# test/services/prospect_brief_generator_test.rb

# frozen_string_literal: true

require 'test_helper'

class ProspectBriefGeneratorTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: 'brief_test_user@example.com',
      password: 'password123',
      name: 'Brief Test User'
    )

    @profile = ProspectingProfile.create!(
      user: @user,
      name: 'Web Dev Profile',
      service: 'Website Development',
      service_description: 'Building fast websites for local businesses',
      target_businesses: ['restaurants', 'real estate agencies'],
      is_default: true
    )

    @business_no_website = {
      name: 'Abuja Garden Bistro',
      category: 'restaurant',
      address: 'Plot 12 Garki, Abuja',
      phone: '+2348012345678',
      website: nil,
      rating: 4.5,
      review_count: 85,
      opportunity_score: 88,
      opportunity_tier: 'HIGH',
      opportunity_factors: ['No website found', 'High customer rating']
    }
  end

  test 'generates structured prospect brief with factual signals and AI interpretation' do
    result = Ai::ProspectBriefGenerator.call(
      business: @business_no_website,
      prospecting_profile: @profile,
      user: @user
    )

    assert result[:success]
    data = result[:data]

    assert_equal 'Abuja Garden Bistro', data[:business_name]
    assert_equal 88, data[:opportunity_score]
    assert_equal 'HIGH', data[:opportunity_tier]

    # Verify Layer 1 factual signals
    signals = data[:signals]
    assert_kind_of Array, signals
    assert signals.any? { |s| s.include?('No website detected in available business data') }
    assert signals.any? { |s| s.include?('Phone available: +2348012345678') }

    # Verify Layer 2 AI interpretation structure
    assert_not_nil data[:summary]
    assert_not_nil data[:why_this_is_a_prospect]
    assert_not_nil data[:recommended_approach]
    assert_not_nil data[:outreach_angle]
  end

  test 'does not alter or recalculate opportunity score' do
    result = Ai::ProspectBriefGenerator.call(
      business: @business_no_website,
      prospecting_profile: @profile,
      user: @user
    )

    assert_equal 88, result[:data][:opportunity_score]
  end

  test 'handles nil profile gracefully with fallback' do
    result = Ai::ProspectBriefGenerator.call(
      business: @business_no_website,
      prospecting_profile: nil,
      user: @user
    )

    assert result[:success]
    assert_not_nil result[:data][:summary]
    assert_not_nil result[:data][:why_this_is_a_prospect]
  end
end
