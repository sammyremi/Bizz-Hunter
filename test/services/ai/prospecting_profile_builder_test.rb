# test/services/ai/prospecting_profile_builder_test.rb

# frozen_string_literal: true

require 'test_helper'

module Ai
  class ProspectingProfileBuilderTest < ActiveSupport::TestCase
    test 'returns error if description is blank or too short' do
      result = ProspectingProfileBuilder.call(description: '  ')
      assert_equal false, result[:success]
      assert_match(/provide a short description/, result[:message])
    end

    test 'successfully validates and normalizes Gemini proposal' do
      mock_gemini_data = {
        'service' => 'website development',
        'service_description' => 'Modern website creation for small businesses.',
        'target_businesses' => ['restaurants', 'Hotels', 'restaurants'],
        'opportunity_signals' => ['no_website', 'Outdated website'],
        'contact_signals' => ['phone_available', 'WhatsApp available']
      }

      with_stub(GeminiClient, :call, { success: true, data: mock_gemini_data }) do
        result = ProspectingProfileBuilder.call(description: 'I build modern websites for restaurants and hotels')
        assert_equal true, result[:success]

        proposal = result[:proposal]
        assert_equal 'Website Development for Restaurants', proposal[:name]
        assert_equal 'Website Development', proposal[:service]
        assert_equal 'Modern website creation for small businesses.', proposal[:service_description]
        assert_equal ['restaurants', 'Hotels'], proposal[:target_businesses] # Deduplicated
        assert_equal ['no_website', 'Outdated website'], proposal[:opportunity_signals]
        assert_equal ['phone_available', 'WhatsApp available'], proposal[:contact_signals]
        assert_equal false, proposal[:is_default]
      end
    end

    test 'handles Gemini API failure gracefully' do
      with_stub(GeminiClient, :call, { success: false, error: 'AI service rate limited' }) do
        result = ProspectingProfileBuilder.call(description: 'I build modern websites for restaurants')
        assert_equal false, result[:success]
        assert_equal 'AI service rate limited', result[:message]
      end
    end
  end
end
