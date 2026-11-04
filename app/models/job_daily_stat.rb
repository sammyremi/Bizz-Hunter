# frozen_string_literal: true

class JobDailyStat < ApplicationRecord
  belongs_to :job

  validates :stat_date, presence: true, uniqueness: { scope: :job_id, message: 'already exists for this Job' }

  # Concurrency-safe atomic increment
  def self.increment_stat!(job_id:, stat_date:, field:, count: 1)
    allowed_fields = %w[
      businesses_found
      unique_new_businesses
      duplicate_businesses
      prospects_qualified
      messages_prepared
      outreach_dispatched
      outreach_confirmed
      outreach_failed
      outreach_uncertain
      prospects_skipped
    ]

    field_name = field.to_s
    return unless allowed_fields.include?(field_name)

    sql = <<~SQL.squish
      INSERT INTO job_daily_stats (id, job_id, stat_date, #{field_name}, created_at, updated_at)
      VALUES (gen_random_uuid(), :job_id, :stat_date, :count, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      ON CONFLICT (job_id, stat_date)
      DO UPDATE SET
        #{field_name} = job_daily_stats.#{field_name} + :count,
        updated_at = CURRENT_TIMESTAMP
    SQL

    sanitize_and_execute = sanitize_sql_array([sql, job_id: job_id, stat_date: stat_date, count: count])
    connection.execute(sanitize_and_execute)
  end
end

