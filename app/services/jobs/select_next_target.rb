# frozen_string_literal: true

# app/services/jobs/select_next_target.rb
module Jobs
  class SelectNextTarget < ApplicationService
    def initialize(job:, lease_duration: 5.minutes)
      @job = job
      @lease_duration = lease_duration
    end

    def call
      return { success: false, message: 'Job is not active' } unless @job.status == 'active'
      return { success: false, message: 'Job is archived' } if @job.archived?

      # Find and lease next eligible target atomically using FOR UPDATE SKIP LOCKED
      claimed_target = nil
      lease_token = nil

      JobTarget.transaction do
        # 1. Recover expired leases if any
        @job.job_targets.where('lease_expires_at <= ?', Time.current).update_all(
          lease_token: nil,
          leased_at: nil,
          lease_expires_at: nil
        )

        # 2. Select eligible target in fair rotation order:
        # Priority:
        # a) unsearched targets (last_searched_at IS NULL)
        # b) least recently searched targets (last_searched_at ASC)
        # c) highest priority (rotation_priority ASC)
        # d) random() for tie-breaking among equally eligible targets
        target_candidate = @job.job_targets
                               .active
                               .unleased_or_expired
                               .order(Arel.sql('last_searched_at ASC NULLS FIRST, rotation_priority ASC, random()'))
                               .lock('FOR UPDATE SKIP LOCKED')
                               .first

        if target_candidate.present?
          lease_token = target_candidate.lease!(@lease_duration)
          claimed_target = target_candidate
        end
      end

      if claimed_target.present?
        {
          success: true,
          target: claimed_target,
          lease_token: lease_token
        }
      else
        {
          success: false,
          message: 'No eligible targets available for this Job right now (all may be currently leased or inactive)'
        }
      end
    end
  end
end

