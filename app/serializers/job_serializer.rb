# frozen_string_literal: true

# app/serializers/job_serializer.rb
class JobSerializer
  def self.render(resource, include_targets: false)
    if resource.is_a?(Enumerable) || resource.is_a?(ActiveRecord::Relation)
      resource.map { |item| format(item, include_targets: include_targets) }
    elsif resource.present?
      format(resource, include_targets: include_targets)
    else
      nil
    end
  end

  private_class_method def self.format(job, include_targets: false)
    data = {
      id: job.id,
      user_id: job.user_id,
      name: job.name,
      status: job.status,
      outreach_mode: job.outreach_mode,
      website_targeting: job.website_targeting,
      daily_discovery_target: job.daily_discovery_target,
      daily_outreach_target: job.daily_outreach_target,
      outreach_interval_seconds: job.outreach_interval_seconds,
      timezone: job.timezone,
      discovery_schedule: job.discovery_schedule,
      discovery_window_start: job.discovery_window_start&.strftime('%H:%M:%S'),
      discovery_window_end: job.discovery_window_end&.strftime('%H:%M:%S'),
      outreach_window_start: job.outreach_window_start&.strftime('%H:%M:%S'),
      outreach_window_end: job.outreach_window_end&.strftime('%H:%M:%S'),
      active_weekdays: job.active_weekdays,
      message_template: job.message_template,
      last_discovery_at: job.last_discovery_at,
      next_discovery_at: job.next_discovery_at,
      last_outreach_at: job.last_outreach_at,
      archived_at: job.archived_at,
      created_at: job.created_at,
      updated_at: job.updated_at,
      prospecting_profile: job.prospecting_profile ? {
        id: job.prospecting_profile.id,
        name: job.prospecting_profile.name,
        service: job.prospecting_profile.service
      } : nil,
      target_counts: {
        total: job.job_targets.count,
        active: job.job_targets.active.count
      }
    }

    if include_targets
      data[:targets] = JobTargetSerializer.render(job.job_targets.order(created_at: :asc))
    end

    data
  end
end

