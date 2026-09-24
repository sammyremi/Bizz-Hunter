# app/services/ai/gemini_client.rb

# frozen_string_literal: true

module Ai
  class GeminiClient < ApplicationService
    include HTTParty

    BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models'

    def initialize(prompt:, system_instruction: nil, response_schema: nil, model: nil, request_id: nil)
      @prompt = prompt.to_s.strip
      @system_instruction = system_instruction.to_s.strip if system_instruction
      @response_schema = response_schema
      @model = model || ENV.fetch('GEMINI_MODEL', 'gemini-3.6-flash')
      @request_id = request_id || "req_#{SecureRandom.hex(6)}"
    end

    def call
      api_key = ENV['GEMINI_API_KEY'].presence
      
      if api_key.blank?
        Rails.logger.error("[GeminiClient][#{request_id}] GEMINI_API_KEY is not set")
        return { success: false, error: 'AI service API key is not configured' }
      end

      return { success: false, error: 'Prompt cannot be blank' } if prompt.blank?

      url = "#{BASE_URL}/#{model}:generateContent?key=#{api_key}"
      log_url = "#{BASE_URL}/#{model}:generateContent?key=[FILTERED]"

      Rails.logger.info("[GeminiClient][#{request_id}] Sending Gemini API request. Model: '#{model}', URL: '#{log_url}', Prompt length: #{prompt.length}")

      response = self.class.post(
        url,
        headers: { 'Content-Type' => 'application/json' },
        body: build_request_payload.to_json,
        timeout: 15
      )

      handle_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error => e
      Rails.logger.error("[GeminiClient][#{request_id}] Request timed out: #{e.class} - #{e.message}")
      { success: false, error: 'AI service request timed out. Please try again.' }
    rescue StandardError => e
      Rails.logger.error("[GeminiClient][#{request_id}] Unexpected error: #{e.class} - #{e.message}")
      { success: false, error: 'AI service unavailable. Please try again later.' }
    end

    private

    attr_reader :prompt, :system_instruction, :response_schema, :model, :request_id

    def build_request_payload
      payload = {
        contents: [
          {
            role: 'user',
            parts: [{ text: prompt }]
          }
        ]
      }

      if system_instruction.present?
        payload[:systemInstruction] = {
          parts: [{ text: system_instruction }]
        }
      end

      if response_schema.present?
        payload[:generationConfig] = {
          responseMimeType: 'application/json',
          responseSchema: response_schema
        }
      end

      payload
    end

    def handle_response(response)
      status_code = response.respond_to?(:code) ? response.code : (response.success? ? 200 : 500)
      parsed = response.respond_to?(:parsed_response) && response.parsed_response.is_a?(Hash) ? response.parsed_response : nil
      error_data = parsed ? parsed['error'] : (response.respond_to?(:dig) ? response.dig('error') : nil)

      unless response.success?
        error_code = error_data&.[]('code') || status_code
        error_status = error_data&.[]('status') || 'UNKNOWN'
        error_msg = error_data&.[]('message') || (response.respond_to?(:body) ? response.body.to_s.truncate(300) : "HTTP #{status_code}")

        Rails.logger.error("[GeminiClient][#{request_id}] Gemini API Error - HTTP Status: #{status_code}, Error Code: #{error_code}, Status: '#{error_status}', Message: '#{error_msg}'")

        return {
          success: false,
          error: error_msg.presence || 'Failed to generate profile with AI. Please try again.',
          status_code: status_code,
          error_code: error_code,
          error_status: error_status,
          error_message: error_msg
        }
      end

      raw_text = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
      if raw_text.blank?
        Rails.logger.error("[GeminiClient][#{request_id}] HTTP #{status_code} - Empty candidate content returned from Gemini. Full response: #{response.respond_to?(:body) ? response.body.to_s.truncate(300) : ''}")
        return { success: false, error: 'AI service returned an empty response.' }
      end

      parsed_data = JSON.parse(raw_text)
      Rails.logger.info("[GeminiClient][#{request_id}] HTTP #{status_code} Success. Parsed Gemini JSON response successfully.")
      { success: true, data: parsed_data }
    rescue JSON::ParserError => e
      Rails.logger.error("[GeminiClient][#{request_id}] HTTP #{status_code} - JSON Parser Error: #{e.message}. Raw text: #{raw_text.to_s.truncate(300)}")
      { success: false, error: 'AI service response could not be parsed.' }
    end
  end
end

