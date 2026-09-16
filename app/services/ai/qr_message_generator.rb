# app/services/ai/qr_message_generator.rb

# frozen_string_literal: true

module Ai
  class QrMessageGenerator < ApplicationService
    RESPONSE_SCHEMA = {
      type: 'OBJECT',
      properties: {
        template: { type: 'STRING' }
      },
      required: ['template']
    }.freeze

    def initialize(prospecting_profile: nil, business_type: nil)
      @profile = prospecting_profile
      @business_type = business_type
    end

    def call
      service_name = profile&.service.presence || 'services'
      service_desc = profile&.service_description.presence || ''
      target_type = business_type.presence || 'business'

      begin
        ai_result = generate_with_gemini(service_name, service_desc, target_type)
        if ai_result[:success] && ai_result[:data] && ai_result[:data]['template'].present?
          template_str = ai_result[:data]['template'].to_s.strip
          if template_str.include?('{{business_name}}')
            return { success: true, template: template_str }
          end
        end
      rescue StandardError => e
        Rails.logger.warn("[QrMessageGenerator] Gemini generation failed: #{e.message}")
      end

      # Safe service-aware fallback template
      fallback = build_fallback_template(service_name, target_type)
      { success: true, template: fallback }
    end

    private

    attr_reader :profile, :business_type

    def generate_with_gemini(service_name, service_desc, target_type)
      system_instruction = <<~TEXT.strip
        You are an expert B2B sales copywriter creating a reusable WhatsApp message template for a service provider reaching out to target businesses (#{target_type}).

        RULES:
        1. CRITICAL: The template MUST include the exact placeholder {{business_name}} for the target business name (e.g. "Hi {{business_name}},").
        2. If a specific service is specified ("#{service_name}"), offer that service.
        3. Keep the template concise, professional, warm, and natural for WhatsApp (2-3 sentences).
        4. End with a soft conversation-starter question.
        5. Return JSON matching schema: { "template": "string" }.
      TEXT

      prompt = <<~PROMPT.strip
        SERVICE OFFERED BY USER:
        - Service: "#{service_name}"
        - Description: "#{service_desc}"
        - Target Industry / Business Type: "#{target_type}"

        Generate a reusable WhatsApp outreach message template containing {{business_name}}.
      PROMPT

      GeminiClient.call(
        prompt: prompt,
        system_instruction: system_instruction,
        response_schema: RESPONSE_SCHEMA
      )
    end

    def build_fallback_template(service_name, target_type)
      if profile.present? && profile.service.present?
        "Hi {{business_name}}, I came across your business and wanted to reach out. I provide #{service_name.strip} for businesses like yours. Would you be open to a quick chat?"
      else
        "Hi {{business_name}}, I came across your business while looking for #{target_type.strip} and wanted to reach out. Would you be open to a quick chat?"
      end
    end
  end
end
