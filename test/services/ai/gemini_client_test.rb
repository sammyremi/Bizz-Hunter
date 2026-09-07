# test/services/ai/gemini_client_test.rb

# frozen_string_literal: true

require 'test_helper'

module Ai
  class GeminiClientTest < ActiveSupport::TestCase
    setup do
      @original_api_key = ENV['GEMINI_API_KEY']
      ENV['GEMINI_API_KEY'] = 'test_gemini_key_123'
    end

    teardown do
      ENV['GEMINI_API_KEY'] = @original_api_key
    end

    test 'returns error if GEMINI_API_KEY is missing' do
      ENV['GEMINI_API_KEY'] = nil

      result = GeminiClient.call(prompt: 'I sell web development')
      assert_equal false, result[:success]
      assert_equal 'AI service API key is not configured', result[:error]
    end

    test 'returns error if prompt is blank' do
      result = GeminiClient.call(prompt: '   ')
      assert_equal false, result[:success]
      assert_equal 'Prompt cannot be blank', result[:error]
    end

    test 'successfully parses structured JSON from Gemini API response' do
      mock_response_body = {
        'candidates' => [
          {
            'content' => {
              'parts' => [
                {
                  'text' => '{"service":"Website Development","service_description":"Web design","target_businesses":["restaurants"],"opportunity_signals":["no_website"],"contact_signals":["whatsapp_available"]}'
                }
              ]
            }
          }
        ]
      }

      fake_resp = Struct.new(:is_success, :data) do
        def success?; is_success; end
        def dig(*keys); data.dig(*keys); end
      end.new(true, mock_response_body)

      with_stub(GeminiClient, :post, fake_resp) do
        result = GeminiClient.call(prompt: 'I build websites for restaurants')
        assert_equal true, result[:success]
        assert_equal 'Website Development', result[:data]['service']
        assert_equal ['restaurants'], result[:data]['target_businesses']
      end
    end

    test 'handles HTTP error response gracefully' do
      fake_resp = Struct.new(:is_success, :code, :data) do
        def success?; is_success; end
        def dig(*keys); data.dig(*keys); end
      end.new(false, 429, { 'error' => { 'message' => 'Resource exhausted' } })

      with_stub(GeminiClient, :post, fake_resp) do
        result = GeminiClient.call(prompt: 'I build websites for restaurants')
        assert_equal false, result[:success]
        assert_equal 'Failed to generate profile with AI. Please try again.', result[:error]
      end
    end
  end
end
