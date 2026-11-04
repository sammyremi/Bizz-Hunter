# frozen_string_literal: true

# app/services/jobs/execute_discovery.rb
module Jobs
  class ExecuteDiscovery < ApplicationService
    MAX_RETRIES = 3

    def initialize(job:, target: nil, max_results: 20)
      @job = job
      @explicit_target = target
      @max_results = max_results
    end

    def call
      start_time = Time.current

      # 1. Eligibility Check
      unless @job.eligible_for_discovery_at?(start_time)
        return {
          success: false,
          reason: :ineligible,
          message: "Job '#{@job.name}' is not currently eligible for discovery (paused, archived, or outside schedule/weekdays)"
        }
      end

      # 2. Select & Claim Target
      target = @explicit_target
      lease_token = nil

      if target.nil?
        selection_result = Jobs::SelectNextTarget.call(job: @job)
        unless selection_result[:success]
          return {
            success: false,
            reason: :no_target_available,
            message: selection_result[:message]
          }
        end
        target = selection_result[:target]
        lease_token = selection_result[:lease_token]
      else
        lease_token = target.lease!
      end

      # 3. Reserve Daily Discovery Quota (Provisional)
      # Reserve expected capacity up to max_results (default 20), bounded by remaining daily capacity
      stat_date = start_time.in_time_zone(@job.timezone).to_date
      reserve_result = QuotaReservation.reserve!(
        job: @job,
        quota_type: 'discovery',
        amount: [@max_results, 1].max
      )

      unless reserve_result[:success]
        # Release the target lease so other workers aren't blocked later
        target.release_lease!
        return {
          success: false,
          reason: :daily_limit_reached,
          message: reserve_result[:message]
        }
      end

      reservation = reserve_result[:reservation]

      # 4. Perform Google Places Search with Bounded Retries
      search_outcome = perform_search_with_retries(target)

      execution_duration = (Time.current - start_time).round(3)

      if search_outcome[:success]
        raw_places = search_outcome[:places] || []
        next_page_token = search_outcome[:next_page_token]
        raw_count = raw_places.size

        # Qualify places and persist unique prospects
        qualification_result = Jobs::QualifyAndPersistPlaces.call(
          job: @job,
          target: target,
          raw_places: raw_places,
          lease_token: lease_token
        )

        unless qualification_result[:success]
          reservation.release!
          target.release_lease!(lease_token)
          return {
            success: false,
            reason: qualification_result[:reason],
            message: qualification_result[:message],
            duration_seconds: execution_duration
          }
        end

        stats = qualification_result[:stats]

        # Fenced update of target progress: only succeeds if this worker still holds the lease token
        updated = target.record_search_outcome!(token: lease_token, discovered_count: raw_count)

        if updated
          # Update Job execution timestamp
          @job.update_columns(last_discovery_at: Time.current)

          # Record raw places found in daily stat.
          JobDailyStat.increment_stat!(
            job_id: @job.id,
            stat_date: stat_date,
            field: :businesses_found,
            count: raw_count
          )

          # Release provisional reservation
          reservation.release!

          Rails.logger.info do
            "[Jobs::ExecuteDiscovery][Job:#{@job.id}][Target:#{target.id}] " \
            "Search and qualification succeeded: #{target.category} in #{target.city_name}, #{target.country.name}. " \
            "Raw: #{raw_count}, Unique: #{stats[:unique_new_count]}, Qualified: #{stats[:qualified_count]}. Duration: #{execution_duration}s."
          end

          {
            success: true,
            job: @job,
            target: target,
            raw_places: raw_places,
            discovered_count: raw_count,
            unique_new_count: stats[:unique_new_count],
            duplicate_count: stats[:duplicate_count],
            qualified_count: stats[:qualified_count],
            disqualified_count: stats[:disqualified_count],
            job_prospects: stats[:persisted_job_prospects],
            next_page_token: next_page_token,
            duration_seconds: execution_duration
          }
        else
          # Fencing failure: Lease was lost or acquired by another worker before completion
          reservation.release!
          Rails.logger.warn("[Jobs::ExecuteDiscovery][Job:#{@job.id}][Target:#{target.id}] Target lease was lost/expired before recording outcome. Discarding search results.")

          {
            success: false,
            reason: :lease_lost,
            message: 'Target lease expired or was reclaimed by another worker during search execution',
            duration_seconds: execution_duration
          }
        end
      else
        # Failed attempt: Fenced release of the target lease
        target.release_lease!(lease_token)

        # Release the unused quota reservation
        reservation.release!

        Rails.logger.warn do
          "[Jobs::ExecuteDiscovery][Job:#{@job.id}][Target:#{target.id}] " \
          "Search failed: #{search_outcome[:error]}. Duration: #{execution_duration}s."
        end

        {
          success: false,
          reason: :search_failed,
          target: target,
          error: search_outcome[:error],
          duration_seconds: execution_duration
        }
      end
    rescue StandardError => e
      Rails.logger.error("[Jobs::ExecuteDiscovery] Unhandled error: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      target&.release_lease!(lease_token)
      reservation&.release! if reservation.present? && reservation.status == 'reserved'
      { success: false, reason: :error, message: e.message }
    end

    private

    def perform_search_with_retries(target)
      attempts = 0

      loop do
        attempts += 1

        begin
          response = GooglePlaces::BusinessSearch.call(
            business_type: target.category,
            city:          target.city_name,
            region:        target.region_name,
            country:       target.country.name,
            page_size:     @max_results
          )

          places = response.fetch('places', [])
          next_token = response['nextPageToken']

          return { success: true, places: places, next_page_token: next_token }
        rescue StandardError => e
          status_code = e.respond_to?(:http_status) ? e.http_status : nil
          retry_after = e.respond_to?(:retry_after) ? e.retry_after : nil
          error_msg   = e.message.to_s.downcase

          # Check if error is transient: HTTP 429, 5xx server errors, timeouts
          is_transient = (status_code == 429) ||
                         (status_code && status_code >= 500) ||
                         error_msg.include?('rate limit') ||
                         error_msg.include?('429') ||
                         error_msg.include?('timeout') ||
                         error_msg.include?('unavailable') ||
                         error_msg.include?('internal')

          # Permanent client errors (400, 401, 403, 404, etc.) must NEVER be retried
          is_permanent_client_error = (status_code && status_code >= 400 && status_code < 500 && status_code != 429)

          if is_transient && !is_permanent_client_error && attempts < MAX_RETRIES
            # Compute delay: Respect Retry-After if provided, else exponential backoff with jitter
            delay = if retry_after && retry_after > 0
                      [retry_after, 10.0].min # Cap at 10 seconds max delay
                    else
                      # Base exponential backoff: 0.2s * 2^(attempts-1) + jitter (0.05..0.2s)
                      base = 0.2 * (2**(attempts - 1))
                      jitter = rand(0.05..0.20)
                      [base + jitter, 10.0].min
                    end

            Rails.logger.warn do
              "[Jobs::ExecuteDiscovery] Transient error '#{e.message}' on attempt #{attempts}/#{MAX_RETRIES}. " \
              "Backing off for #{delay.round(2)}s (Retry-After: #{retry_after || 'none'})..."
            end

            sleep(delay)
          else
            # Permanent error or exhausted retries
            return { success: false, error: e.message, attempts: attempts }
          end
        end
      end
    end
  end
end

