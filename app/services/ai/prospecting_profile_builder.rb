# app/services/ai/prospecting_profile_builder.rb

# frozen_string_literal: true

module Ai
  class ProspectingProfileBuilder < ApplicationService
    SYSTEM_INSTRUCTION = <<~TEXT.strip
      You are Bizz-Hunter's Prospecting Strategy AI. Your goal is to analyze a user's natural language description of what product or service they sell, and infer a structured Prospecting Profile.

      Instructions:
      1. Extract the core service name into "service" (e.g., "Website Development", "Solar Installation", "Commercial Cleaning", "Custom Software"). Do not limit to hard-coded categories.
      2. Summarize what the user offers into "service_description" in 1-2 concise sentences.
      3. Identify 1 to 5 target business categories into "target_businesses" (e.g., ["Restaurants", "Hotels", "Barbershops", "Real Estate Agencies"]).
      4. Identify 1 to 5 potential opportunity signals relevant to offering this service into "opportunity_signals" (e.g., ["No website", "Outdated website", "Poor online reviews", "No online booking"]). These are hypothetical characteristics that make a business worth contacting. Never claim to have verified real-world business facts.
      5. Identify 1 to 3 relevant contact signals into "contact_signals" (e.g., ["Phone available", "WhatsApp available", "Email available"]).
      6. Return ONLY structured data adhering strictly to the JSON schema.
    TEXT

    RESPONSE_SCHEMA = {
      type: 'OBJECT',
      properties: {
        service: { type: 'STRING' },
        service_description: { type: 'STRING' },
        target_businesses: {
          type: 'ARRAY',
          items: { type: 'STRING' }
        },
        opportunity_signals: {
          type: 'ARRAY',
          items: { type: 'STRING' }
        },
        contact_signals: {
          type: 'ARRAY',
          items: { type: 'STRING' }
        }
      },
      required: %w[service service_description target_businesses opportunity_signals contact_signals]
    }.freeze

    def initialize(description:)
      @description = description.to_s.strip
    end

    def call
      if description.blank? || description.length < 3
        return { success: false, message: 'Please provide a short description of what you sell or offer.' }
      end

      result = GeminiClient.call(
        prompt: description,
        system_instruction: SYSTEM_INSTRUCTION,
        response_schema: RESPONSE_SCHEMA
      )

      unless result[:success]
        return { success: false, message: result[:error] || 'Failed to generate profile with AI.' }
      end

      normalized = validate_and_normalize(result[:data])
      if normalized
        { success: true, proposal: normalized }
      else
        { success: false, message: 'AI generated an incomplete profile. Please try rephrasing your description.' }
      end
    end

    private

    attr_reader :description

    def validate_and_normalize(data)
      return nil unless data.is_a?(Hash)

      service = data['service'].to_s.strip.titleize
      return nil if service.blank?

      service_description = data['service_description'].to_s.strip
      target_businesses = normalize_string_array(data['target_businesses'])
      opportunity_signals = normalize_string_array(data['opportunity_signals'])
      contact_signals = normalize_string_array(data['contact_signals'])

      # Generate a clean profile name based on service & target
      primary_target = target_businesses.first
      name = if primary_target.present?
               "#{service} for #{primary_target.pluralize.titleize}"
             else
               "#{service} Prospecting"
             end

      {
        name: name,
        service: service,
        service_description: service_description,
        target_businesses: target_businesses,
        opportunity_signals: opportunity_signals,
        contact_signals: contact_signals,
        is_default: false
      }
    end

    def normalize_string_array(arr)
      return [] unless arr.is_a?(Array)

      seen = Set.new
      result = []

      arr.each do |item|
        str = item.to_s.strip
        next if str.blank?

        key = str.downcase
        unless seen.include?(key)
          seen.add(key)
          result << str
        end
      end

      result
    end
  end
end
