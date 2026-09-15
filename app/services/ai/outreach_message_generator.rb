# app/services/ai/outreach_message_generator.rb

# frozen_string_literal: true

require 'erb'

module Ai
  class OutreachMessageGenerator < ApplicationService
    RESPONSE_SCHEMA = {
      type: 'OBJECT',
      properties: {
        message: { type: 'STRING' }
      },
      required: ['message']
    }.freeze

    def initialize(search_result:, user:)
      @search_result = search_result
      @user          = user
      @search        = search_result.search
      @profile       = @search&.prospecting_profile
    end

    def call
      # Validate profile and service availability
      if profile.blank? || profile.service.blank? || profile.service_description.blank?
        Rails.logger.warn do
          "[OutreachMessageGenerator] Missing or incomplete Prospecting Profile for SearchResult ID: #{search_result.id}, " \
          "Search ID: #{search&.id}, Profile ID: #{profile&.id}"
        end
        return {
          success: false,
          message: 'A Prospecting Profile with a service is required to generate a personalized message.'
        }
      end

      business_name = search_result.name.presence || 'there'
      raw_phone     = search_result.phone.presence || search_result.national_phone.presence || ''
      clean_phone   = raw_phone.to_s.gsub(/\D/, '')

      if clean_phone.blank?
        return { success: false, message: 'This business does not have a phone number available for WhatsApp.' }
      end

      tone   = user&.effective_ai_tone || 'Professional'
      length = user&.effective_ai_length || 'Short'

      Rails.logger.debug do
        "[OutreachMessageGenerator] Search ID: '#{search&.id}', SearchResult ID: '#{search_result.id}', " \
        "Profile ID: '#{profile.id}', Service: '#{profile.service}'"
      end

      # Attempt AI message generation via GeminiClient
      ai_result = generate_with_gemini(tone, length)

      message = if ai_result[:success] && ai_result[:data] && ai_result[:data]['message'].present?
                  ai_result[:data]['message'].to_s.strip
                else
                  build_fallback_message(business_name, tone)
                end

      # URL encode message for WhatsApp deep-link
      encoded_text = ERB::Util.url_encode(message)
      whatsapp_url = "https://wa.me/#{clean_phone}?text=#{encoded_text}"

      {
        success: true,
        data: {
          message:       message,
          whatsapp_url:  whatsapp_url,
          business_name: business_name,
          phone:         clean_phone,
          tone:          tone,
          length:        length
        }
      }
    end

    private

    attr_reader :search_result, :user, :search, :profile

    def generate_with_gemini(tone, length)
      prompt = build_prompt(tone, length)
      system_instruction = build_system_instruction(tone, length)

      GeminiClient.call(
        prompt: prompt,
        system_instruction: system_instruction,
        response_schema: RESPONSE_SCHEMA
      )
    end

    def build_system_instruction(tone, length)
      <<~TEXT.strip
        You are an expert B2B sales outreach copywriter writing personalized WhatsApp messages to small business owners on behalf of a service provider.

        RULES:
        1. CRITICAL: The user offers "#{profile.service}". You MUST write an outreach message offering "#{profile.service}". You MUST NEVER replace or infer a different service (such as legal, accounting, consulting, etc.) based on the target business's category.
        2. Write a direct, natural, human-sounding outreach message suitable for WhatsApp.
        3. Use the real business name naturally in the greeting (e.g. "Hi Mama's Kitchen,").
        4. Match the requested tone (#{profile_tone_guideline(tone)}) and length (#{profile_length_guideline(length)}).
        5. ABSOLUTELY NEVER mention internal metrics, scores, tiers, or Bizz-Hunter ("score", "tier", "87 points", "Bizz-Hunter").
        6. ABSOLUTELY NEVER invent or hallucinate unprovided facts, pricing, discounts, promotions, awards, or fake claims.
        7. Do NOT praise the business with fake claims like "I was really impressed by your work" unless supported by provided facts.
        8. Do NOT claim the business lacks a website unless explicitly stated in the context facts.
        9. End with a soft, low-pressure question to start a conversation.
        10. Return JSON matching schema: { "message": "string" }.
      TEXT
    end

    def build_prompt(tone, length)
      b_name      = search_result.name.presence || 'Business'
      b_category  = search_result.business_type.presence || Array(search_result.types).first || 'local business'
      b_location  = search_result.city.presence || search_result.address.presence || 'your area'
      has_website = search_result.website.present?

      service_name = profile.service
      service_desc = profile.service_description
      targets      = profile.target_businesses.join(', ')

      factors = Array(search_result.opportunity_factors).join(', ')

      <<~PROMPT.strip
        USER'S OFFERED SERVICE (MUST BE OFFERED):
        - Service: "#{service_name}"
        - Service Description: "#{service_desc}"
        - Targeted Industries: #{targets.presence || 'Local businesses'}

        PROSPECT BUSINESS (Recipient):
        - Business Name: "#{b_name}"
        - Industry / Category: #{b_category}
        - Location: #{b_location}
        - Has Active Website: #{has_website ? 'Yes' : 'No'}
        - Observed Business Context: #{factors.presence || 'Active local business'}

        USER OUTREACH PREFERENCES:
        - Tone: #{tone}
        - Length: #{length}

        Generate a personalized WhatsApp message for #{b_name} offering #{service_name}.
      PROMPT
    end

    def build_fallback_message(b_name, tone)
      service_text = profile.service.strip
      greeting = tone.to_s.downcase == 'casual' ? "Hey #{b_name}," : "Hi #{b_name},"

      if website_service? && search_result.website.blank?
        "#{greeting} I came across your business and noticed you don't currently have a website. I help businesses like yours with #{service_text}. Would you be open to a quick chat about getting one set up?"
      else
        "#{greeting} I came across your business and wanted to reach out. I provide #{service_text} for businesses like yours. Would you be open to a quick chat?"
      end
    end

    def website_service?
      return false if profile.blank?
      s = profile.service.to_s.downcase
      d = profile.service_description.to_s.downcase
      s.include?('web') || d.include?('web') || s.include?('site')
    end

    def profile_tone_guideline(tone)
      case tone.to_s.capitalize
      when 'Casual' then 'Casual, conversational, warm'
      when 'Friendly' then 'Friendly, polite, approachable'
      when 'Direct' then 'Direct, concise, value-focused'
      else 'Professional, respectful, clear'
      end
    end

    def profile_length_guideline(length)
      case length.to_s.capitalize
      when 'Medium' then 'Medium length (3-4 sentences, ~70 words)'
      else 'Short length (2-3 sentences, ~40 words)'
      end
    end
  end
end
