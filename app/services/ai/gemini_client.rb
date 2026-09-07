# app/services/ai/gemini_client.rb

# frozen_string_literal: true

module Ai
  class GeminiClient < ApplicationService
    include HTTParty

    BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models'

    def initialize(prompt:, system_instruction: nil, response_schema: nil, model: nil)
      @prompt = prompt.to_s.strip
      @system_instruction = system_instruction.to_s.strip if system_instruction
      @response_schema = response_schema
      @model = model || ENV.fetch('GEMINI_MODEL', 'gemini-3.6-flash')
    end

    def call
      api_key = ENV['GEMINI_API_KEY'].presence
      
      if api_key.blank?
        Rails.logger.error('[GeminiClient] GEMINI_API_KEY is not set')
        return { success: false, error: 'AI service API key is not configured' }
      end

      return { success: false, error: 'Prompt cannot be blank' } if prompt.blank?

      url = "#{BASE_URL}/#{model}:generateContent?key=#{api_key}"

      response = self.class.post(
        url,
        headers: { 'Content-Type' => 'application/json' },
        body: build_request_payload.to_json,
        timeout: 15
      )

      handle_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error => e
      Rails.logger.error("[GeminiClient] Request timed out: #{e.message}")
      { success: false, error: 'AI service request timed out. Please try again.' }
    rescue StandardError => e
      Rails.logger.error("[GeminiClient] Unexpected error: #{e.message}")
      { success: false, error: 'AI service unavailable. Please try again later.' }
    end

    private

    attr_reader :prompt, :system_instruction, :response_schema, :model

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
      unless response.success?
        error_msg = response.dig('error', 'message') || "HTTP #{response.code}"
        Rails.logger.error("[GeminiClient] API Error (#{response.code}): #{error_msg}")
        return { success: false, error: 'Failed to generate profile with AI. Please try again.' }
      end

      raw_text = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
      if raw_text.blank?
        Rails.logger.error('[GeminiClient] Empty candidate content returned from Gemini')
        return { success: false, error: 'AI service returned an empty response.' }
      end

      parsed_data = JSON.parse(raw_text)
      { success: true, data: parsed_data }
    rescue JSON::ParserError => e
      Rails.logger.error("[GeminiClient] JSON Parser Error: #{e.message}")
      { success: false, error: 'AI service response could not be parsed.' }
    end
  end
end
