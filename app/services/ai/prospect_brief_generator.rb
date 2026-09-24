# app/services/ai/prospect_brief_generator.rb

# frozen_string_literal: true

module Ai
  class ProspectBriefGenerator < ApplicationService
    RESPONSE_SCHEMA = {
      type: 'OBJECT',
      properties: {
        summary: { type: 'STRING' },
        why_this_is_a_prospect: { type: 'STRING' },
        recommended_approach: { type: 'STRING' },
        outreach_angle: { type: 'STRING' }
      },
      required: %w[summary why_this_is_a_prospect recommended_approach outreach_angle]
    }.freeze

    def initialize(business:, prospecting_profile: nil, user: nil)
      @business = business.is_a?(SearchResult) ? business_to_hash(business) : (business || {}).symbolize_keys
      @profile = prospecting_profile
      @user = user
    end

    def call
      facts = extract_factual_signals(@business)
      opp_score = (@business[:opportunity_score] || calculate_score[:score]).to_i
      opp_tier = (@business[:opportunity_tier] || @business[:opportunity_level] || 'STANDARD').to_s.upcase
      opp_factors = Array(@business[:opportunity_factors]).presence || calculate_score[:factors]

      ai_brief = generate_ai_interpretation(facts, opp_score, opp_factors)

      {
        success: true,
        data: {
          business_name: @business[:name] || @business[:business_name] || 'Business',
          opportunity_score: opp_score,
          opportunity_tier: opp_tier,
          signals: facts,
          summary: ai_brief[:summary],
          why_this_is_a_prospect: ai_brief[:why_this_is_a_prospect],
          recommended_approach: ai_brief[:recommended_approach],
          outreach_angle: ai_brief[:outreach_angle],
          prospecting_profile_id: @profile&.id,
          prospecting_profile_name: @profile&.name || 'General Prospecting'
        }
      }
    end

    private

    attr_reader :business, :profile, :user

    def extract_factual_signals(b)
      signals = []

      # Target business match signal
      if profile&.target_businesses.present?
        signals << "Target business match: #{profile.target_businesses.join(', ')}"
      elsif b[:category].present? || b[:types].present?
        cat = b[:category] || Array(b[:types]).first
        signals << "Category: #{cat.to_s.titleize}"
      end

      # Website signal (factual - no claims if unknown)
      if b[:website].present?
        signals << "Website active: #{b[:website]}"
      else
        signals << "No website detected in available business data"
      end

      # Phone signal
      phone_num = b[:phone].presence || b[:national_phone].presence || b[:international_phone_number].presence
      if phone_num.present?
        signals << "Phone available: #{phone_num}"
      else
        signals << "No phone line recorded"
      end

      # Rating & reviews signal
      if b[:rating].present? && b[:rating].to_f > 0
        rev_count = b[:review_count].to_i
        signals << "Rating: #{b[:rating]} ★#{rev_count > 0 ? " (#{rev_count} reviews)" : ''}"
      end

      # Location signal
      if b[:address].present?
        signals << "Location: #{b[:address]}"
      end

      signals
    end

    def generate_ai_interpretation(facts, score, factors)
      service_name = profile&.service.presence || 'B2B Services'
      service_desc = profile&.service_description.presence || ''
      b_name = business[:name] || business[:business_name] || 'Target Business'

      system_instruction = <<~TEXT.strip
        You are an expert B2B sales strategist for Bizz-Hunter SaaS.
        Your task is to analyze a prospective target business for a user selling "#{service_name}".

        CRITICAL CONSTRAINTS:
        1. DO NOT INVENT FACTS. Rely STRICTLY on the provided factual signals.
        2. If a website is missing, note that "no website was found in available business data". Do NOT claim their website is broken or down unless explicitly stated.
        3. Do NOT claim the business uses WhatsApp or has a broken line unless backed by facts.
        4. Do NOT calculate or change the opportunity score. The score is strictly provided.
        5. RESPECT THE OPPORTUNITY TIER AND SCORE. Do NOT describe a LOW opportunity (or low score < 40) as a "Strong opportunity match". If the score is low or tier is LOW, describe it accurately as a lower-priority match or secondary prospect based on the facts provided.
        6. Return structured JSON matching schema: summary, why_this_is_a_prospect, recommended_approach, outreach_angle.
      TEXT

      prompt = <<~PROMPT.strip
        USER PROSPECTING PROFILE:
        - Profile Name: "#{profile&.name || 'Default'}"
        - Service Offered: "#{service_name}"
        - Service Description: "#{service_desc}"

        TARGET BUSINESS facts:
        - Business Name: "#{b_name}"
        - Opportunity Score: #{score}
        - Opportunity Tier: #{business[:opportunity_tier] || business[:opportunity_level] || 'MEDIUM'}
        - Factual Signals:
          #{facts.map { |f| "  * #{f}" }.join("\n")}
        - Opportunity Factors:
          #{factors.map { |f| "  * #{f}" }.join("\n")}

        Generate a concise, professional AI Prospect Brief explaining why this business is worth contacting and how to approach them.
      PROMPT

      res = GeminiClient.call(
        prompt: prompt,
        system_instruction: system_instruction,
        response_schema: RESPONSE_SCHEMA
      )

      if res[:success] && res[:data].present?
        {
          summary: res[:data]['summary'].presence || "Matches your #{service_name} prospecting profile.",
          why_this_is_a_prospect: res[:data]['why_this_is_a_prospect'].presence || "This business matches your target criteria based on available signals.",
          recommended_approach: res[:data]['recommended_approach'].presence || "Lead with a conversation about their business goals.",
          outreach_angle: res[:data]['outreach_angle'].presence || "Service discussion"
        }
      else
        fallback_interpretation(b_name, service_name)
      end
    rescue StandardError => e
      Rails.logger.warn("[ProspectBriefGenerator] Gemini brief generation failed: #{e.message}")
      fallback_interpretation(b_name, service_name)
    end

    def fallback_interpretation(b_name, service_name)
      has_no_website = business[:website].blank?
      opp_tier = (business[:opportunity_tier] || business[:opportunity_level] || 'MEDIUM').to_s.upcase

      tier_summary = case opp_tier
                     when 'HIGH'
                       "High opportunity match for your #{service_name} prospecting profile."
                     when 'LOW'
                       "Lower-priority prospect for your #{service_name} prospecting profile."
                     else
                       "Moderate opportunity match for your #{service_name} prospecting profile."
                     end

      why = if has_no_website
              "#{b_name} matches your target market, and no website was found in the available business data. This aligns directly with your #{service_name} offering."
            else
              "#{b_name} is an established local business matching your #{service_name} target market."
            end

      approach = if has_no_website
                   "Reach out to discuss how a modern online presence can help drive new customer inquiries."
                 else
                   "Focus on how your #{service_name} service can help optimize their current operations."
                 end

      {
        summary: tier_summary,
        why_this_is_a_prospect: why,
        recommended_approach: approach,
        outreach_angle: has_no_website ? "Online presence discussion" : "Service optimization"
      }
    end

    def calculate_score
      @calculate_score ||= OpportunityScoreCalculator.call(business: business, profile: profile)
    end

    def business_to_hash(sb)
      {
        id: sb.id,
        google_place_id: sb.google_place_id,
        name: sb.name,
        category: sb.category,
        address: sb.address,
        phone: sb.phone,
        national_phone: sb.national_phone,
        international_phone_number: sb.international_phone_number,
        website: sb.website,
        rating: sb.rating,
        review_count: sb.review_count,
        opportunity_score: sb.opportunity_score,
        opportunity_tier: sb.opportunity_tier,
        opportunity_level: sb.opportunity_level,
        opportunity_factors: sb.opportunity_factors
      }
    end
  end
end
