# frozen_string_literal: true

# app/jobs/jobs/discovery_execution_job.rb
module Jobs
  class DiscoveryExecutionJob < ApplicationJob
    queue_as :default

    # Discards if Job has been deleted or permanently archived
    discard_on ActiveRecord::RecordNotFound

    def perform(job_id)
      job = Job.find_by(id: job_id)
      return if job.nil?
      return unless job.status == 'active'
      return if job.archived?

      # Verify schedule eligibility before execution
      unless job.eligible_for_discovery_at?
        Rails.logger.info("[Jobs::DiscoveryExecutionJob] Job '#{job.name}' (ID: #{job.id}) is outside discovery window/weekdays. Skipping.")
        return
      end

      # Execute discovery orchestration
      result = Jobs::ExecuteDiscovery.call(job: job)

      if result[:success]
        Rails.logger.info("[Jobs::DiscoveryExecutionJob] Successfully executed discovery for Job '#{job.name}'. Discovered: #{result[:discovered_count]} places.")
      else
        Rails.logger.warn("[Jobs::DiscoveryExecutionJob] Discovery halted for Job '#{job.name}'. Reason: #{result[:reason]} - #{result[:message] || result[:error]}")
      end
    end
  end
end

