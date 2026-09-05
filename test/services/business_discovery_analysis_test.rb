# test/services/business_discovery_analysis_test.rb

# frozen_string_literal: true

require 'test_helper'

class BusinessDiscoveryAnalysisTest < ActiveSupport::TestCase
  test 'aggregates business analytics correctly' do
    businesses = [
      {
        name: 'Alpha Cafe',
        types: ['cafe'],
        address: 'Wuse 2, Abuja, Nigeria',
        rating: 4.6,
        review_count: 120,
        phone: '+2348011111111',
        website: nil
      },
      {
        name: 'Beta Tech',
        types: ['technology'],
        address: 'Garki, Abuja, Nigeria',
        rating: 3.8,
        review_count: 15,
        phone: nil,
        website: 'https://beta.com'
      }
    ]

    analysis = GooglePlaces::BusinessDiscoveryAnalysis.call(businesses: businesses)

    assert_equal 2, analysis[:summary][:total_businesses]
    assert_equal 1, analysis[:summary][:no_website_count]
    assert_equal 1, analysis[:summary][:phone_available_count]
    assert_equal 1, analysis[:summary][:whatsapp_available_count]
    assert_equal 1, analysis[:summary][:high_opportunity_count]

    assert_equal 1, analysis[:opportunity][:high]
    assert_equal 1, analysis[:opportunity][:low]

    assert_equal 2, analysis[:top_prospects].size
    assert_equal 'Alpha Cafe', analysis[:top_prospects].first[:name]
  end

  test 'returns empty analysis for empty businesses input' do
    analysis = GooglePlaces::BusinessDiscoveryAnalysis.call(businesses: [])
    assert_equal 0, analysis[:summary][:total_businesses]
    assert_equal 0, analysis[:summary][:no_website_count]
    assert_empty analysis[:top_prospects]
  end
end
