# frozen_string_literal: true

# app/jobs/jobs/discovery_scheduler_job.rb
module Jobs
  class DiscoverySchedulerJob < ApplicationJob
    queue_as :default

    # Polled periodically via Solid Queue recurring schedule
    def perform
      active_jobs = Job.active.where(archived_at: nil)
      current_time = Time.current

      active_jobs.find_each do |job|
        next unless job.eligible_for_discovery_at?(current_time)

        # Concurrency safety: check if a discovery execution job is already pending/ready for this Job
        if pending_discovery_job_exists?(job.id)
          Rails.logger.info("[Jobs::DiscoverySchedulerJob] Job '#{job.name}' (ID: #{job.id}) already has a pending discovery job. Skipping duplicate enqueue.")
          next
        end

        # Enqueue a discrete discovery job for this eligible Job
        Jobs::DiscoveryExecutionJob.perform_later(job.id)
      end
    end

    private

    def pending_discovery_job_exists?(job_id)
      # In Rails test environment, check ActiveJob's test adapter enqueued_jobs if active
      if Rails.env.test? && ActiveJob::Base.queue_adapter.is_a?(ActiveJob::QueueAdapters::TestAdapter)
        return ActiveJob::Base.queue_adapter.enqueued_jobs.any? do |job|
          job[:job] == Jobs::DiscoveryExecutionJob && job[:args] == [job_id]
        end
      end

      return false unless defined?(SolidQueue::Job) && SolidQueue::Job.table_exists?

      # Query unexecuted or claimed solid queue jobs for this class and job_id
      SolidQueue::Job.where(class_name: 'Jobs::DiscoveryExecutionJob', finished_at: nil)
                     .where("arguments LIKE ?", "%#{job_id}%")
                     .exists?
    rescue StandardError => e
      Rails.logger.warn("[Jobs::DiscoverySchedulerJob] Error checking pending jobs: #{e.message}")
      false
    end
  end
end

