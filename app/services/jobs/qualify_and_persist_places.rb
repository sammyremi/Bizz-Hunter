# frozen_string_literal: true

# app/services/jobs/qualify_and_persist_places.rb
module Jobs
  class QualifyAndPersistPlaces < ApplicationService
    def initialize(job:, target:, raw_places:, lease_token:)
      @job = job
      @target = target
      @raw_places = Array(raw_places)
      @lease_token = lease_token
      @user = job.user
    end

    def call
      # Safety check: if worker doesn't hold a valid active lease, abort
      unless @target.lease_token == @lease_token && @target.lease_expires_at > Time.current
        return {
          success: false,
          reason: :lease_lost,
          message: 'Target lease expired or belongs to another worker before qualification'
        }
      end

      stat_date = Time.current.in_time_zone(@job.timezone).to_date
      results = {
        raw_count: @raw_places.size,
        unique_new_count: 0,
        duplicate_count: 0,
        qualified_count: 0,
        disqualified_count: 0,
        persisted_job_prospects: []
      }

      @raw_places.each do |place|
        # Verify lease is still held during processing
        unless @target.lease_token == @lease_token && @target.lease_expires_at > Time.current
          Rails.logger.warn("[Jobs::QualifyAndPersistPlaces] Lease lost during processing batch for Job #{@job.id}")
          return {
            success: false,
            reason: :lease_lost,
            message: 'Target lease expired during place batch qualification',
            partial_results: results
          }
        end

        place_id = place['id'] || place['place_id'] || place[:id]
        next if place_id.blank?

        normalized = normalize_place(place)
        website_assessment = evaluate_website(normalized)
        qualification = evaluate_qualification(normalized, website_assessment)

        # Atomic find-or-create Prospect and JobProspect within transaction
        begin
          ActiveRecord::Base.transaction do
            # 1. Deduplication check: Has this user ever seen this place before?
            is_known_in_search = SearchResult.where(user_id: @user.id, google_place_id: place_id).exists?
            existing_prospect = Prospect.find_by(user_id: @user.id, google_place_id: place_id)
            is_known_in_job = JobProspect.joins(:job)
                                         .where(jobs: { user_id: @user.id })
                                         .where(prospect_id: existing_prospect&.id)
                                         .exists? if existing_prospect.present?

            is_already_known = is_known_in_search || existing_prospect.present? || is_known_in_job

            # 2. Find or create Prospect record
            prospect = existing_prospect
            if prospect.nil?
              prospect = create_prospect!(normalized)
            else
              # Existing prospect reused: enrich non-destructive fields if previously blank
              enrich_prospect_if_blank!(prospect, normalized)
            end

            # 3. Find or create JobProspect association
            job_prospect = JobProspect.find_by(job_id: @job.id, prospect_id: prospect.id)
            if job_prospect.nil?
              # Determine initial review status based on job's outreach mode
              review_status = @job.outreach_mode == 'automatic' ? 'auto_approved' : 'pending'

              # Calculate opportunity score if profile is present
              score = calculate_score(normalized)

              job_prospect = @job.job_prospects.create!(
                prospect: prospect,
                search_result: find_matching_search_result(place_id),
                qualification_status: qualification[:status],
                qualification_reason: qualification[:reason],
                website_status: website_assessment[:status],
                review_status: review_status,
                opportunity_score: score
              )
            end

            # 4. Accounting tracking
            if is_already_known
              results[:duplicate_count] += 1
            else
              results[:unique_new_count] += 1
            end

            if qualification[:status] == 'qualified'
              results[:qualified_count] += 1
            else
              results[:disqualified_count] += 1
            end

            results[:persisted_job_prospects] << job_prospect
          end
        rescue ActiveRecord::RecordNotUnique
          # Concurrent worker processed this place simultaneously; treat as duplicate
          results[:duplicate_count] += 1
        end
      end

      # Increment persistent daily statistics atomically
      JobDailyStat.increment_stat!(
        job_id: @job.id,
        stat_date: stat_date,
        field: :unique_new_businesses,
        count: results[:unique_new_count]
      ) if results[:unique_new_count] > 0

      JobDailyStat.increment_stat!(
        job_id: @job.id,
        stat_date: stat_date,
        field: :duplicate_businesses,
        count: results[:duplicate_count]
      ) if results[:duplicate_count] > 0

      JobDailyStat.increment_stat!(
        job_id: @job.id,
        stat_date: stat_date,
        field: :prospects_qualified,
        count: results[:qualified_count]
      ) if results[:qualified_count] > 0

      {
        success: true,
        stats: results
      }
    end

    private

    def normalize_place(place)
      display_name = place.dig('displayName', 'text') || place['displayName'] || place[:name]
      address = place['formattedAddress'] || place['address'] || place[:address]
      lat = place.dig('location', 'latitude') || place[:latitude]
      lng = place.dig('location', 'longitude') || place[:longitude]
      rating = place['rating'] || place[:rating]
      review_count = place['userRatingCount'] || place['review_count'] || place[:review_count] || 0
      int_phone = place['internationalPhoneNumber'] || place[:international_phone_number]
      nat_phone = place['nationalPhoneNumber'] || place[:national_phone] || place[:phone_number]
      website = place['websiteUri'] || place['website'] || place[:website]
      maps_url = place['googleMapsUri'] || place['google_maps_url'] || place[:google_maps_url]
      types = place['types'] || place[:types] || []

      {
        place_id: place['id'] || place['place_id'] || place[:id],
        name: display_name.presence || 'Unknown Business',
        address: address,
        latitude: lat,
        longitude: lng,
        rating: rating,
        review_count: review_count,
        international_phone_number: int_phone,
        phone_number: nat_phone.presence || int_phone,
        website: website.presence,
        google_maps_url: maps_url,
        types: types,
        raw_place: place
      }
    end

    def evaluate_website(normalized)
      # Google Places API field: websiteUri
      # Rule: A missing website field from Google Places does not conclusively prove
      # the business has no website; it indicates 'no_website_found' in Google Places metadata.
      # If website is present: 'website_found'.
      # Supported statuses in schema: no_website_found, website_found, weak_or_outdated, unknown, needs_verification
      if normalized[:raw_place].key?('websiteUri') || normalized[:raw_place].key?('website') || normalized[:raw_place].key?(:website)
        if normalized[:website].present?
          { status: 'website_found', url: normalized[:website] }
        else
          { status: 'no_website_found', url: nil }
        end
      else
        # Website field was not queried or absent from payload entirely
        { status: 'unknown', url: nil }
      end
    end

    def evaluate_qualification(normalized, website_assessment)
      targeting = @job.website_targeting # 'no_website', 'weak_or_outdated', 'both'
      web_status = website_assessment[:status]

      # Check website targeting rules
      case targeting
      when 'no_website'
        if web_status == 'no_website_found'
          {
            status: 'qualified',
            reason: "Targeting '#{targeting}': No website was found in Google Places business data."
          }
        elsif web_status == 'unknown'
          {
            status: 'pending_criteria',
            reason: "Targeting '#{targeting}': Website data is unknown and requires verification."
          }
        else
          {
            status: 'disqualified',
            reason: "Targeting '#{targeting}': Business has an active website (#{website_assessment[:url]})."
          }
        end
      when 'weak_or_outdated'
        if web_status == 'weak_or_outdated'
          {
            status: 'qualified',
            reason: "Targeting '#{targeting}': Business has an outdated or weak online presence."
          }
        elsif web_status == 'website_found'
          # Website found but not inspected for quality yet
          {
            status: 'pending_criteria',
            reason: "Targeting '#{targeting}': Website exists (#{website_assessment[:url]}); pending website quality evaluation."
          }
        else
          {
            status: 'disqualified',
            reason: "Targeting '#{targeting}': Business has website status '#{web_status}'."
          }
        end
      when 'both'
        if web_status.in?(%w[no_website_found website_found weak_or_outdated])
          {
            status: 'qualified',
            reason: "Targeting 'both': Business matches criteria (website status: #{web_status})."
          }
        else
          {
            status: 'pending_criteria',
            reason: "Targeting 'both': Website status is unknown; pending verification."
          }
        end
      else
        { status: 'qualified', reason: 'Matches job criteria.' }
      end
    end

    def create_prospect!(normalized)
      @user.prospects.create!(
        business_name: normalized[:name],
        google_place_id: normalized[:place_id],
        address: normalized[:address],
        category: @target.category,
        latitude: normalized[:latitude],
        longitude: normalized[:longitude],
        rating: normalized[:rating],
        review_count: normalized[:review_count],
        international_phone_number: normalized[:international_phone_number],
        phone_number: normalized[:phone_number],
        website: normalized[:website],
        google_maps_url: normalized[:google_maps_url],
        status: 'NEW'
      )
    end

    def enrich_prospect_if_blank!(prospect, normalized)
      updates = {}
      updates[:address] = normalized[:address] if prospect.address.blank? && normalized[:address].present?
      updates[:phone_number] = normalized[:phone_number] if prospect.phone_number.blank? && normalized[:phone_number].present?
      updates[:international_phone_number] = normalized[:international_phone_number] if prospect.international_phone_number.blank? && normalized[:international_phone_number].present?
      updates[:website] = normalized[:website] if prospect.website.blank? && normalized[:website].present?
      updates[:google_maps_url] = normalized[:google_maps_url] if prospect.google_maps_url.blank? && normalized[:google_maps_url].present?
      updates[:rating] = normalized[:rating] if prospect.rating.blank? && normalized[:rating].present?
      updates[:review_count] = normalized[:review_count] if (prospect.review_count.blank? || prospect.review_count == 0) && normalized[:review_count].to_i > 0

      prospect.update_columns(updates.merge(updated_at: Time.current)) if updates.present?
    end

    def find_matching_search_result(place_id)
      SearchResult.where(user_id: @user.id, google_place_id: place_id).order(created_at: :desc).first
    end

    def calculate_score(normalized)
      return nil if @job.prospecting_profile.nil?

      business_data = {
        name: normalized[:name],
        types: normalized[:types],
        category: @target.category,
        address: normalized[:address],
        phone: normalized[:phone_number],
        international_phone_number: normalized[:international_phone_number],
        website: normalized[:website],
        rating: normalized[:rating],
        review_count: normalized[:review_count]
      }

      score_result = OpportunityScoreCalculator.call(
        business: business_data,
        profile: @job.prospecting_profile
      )

      score_result[:score] || 0
    rescue StandardError => e
      Rails.logger.warn("[Jobs::QualifyAndPersistPlaces] Failed to calculate opportunity score: #{e.message}")
      nil
    end
  end
end

