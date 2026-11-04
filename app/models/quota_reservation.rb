# frozen_string_literal: true

require 'securerandom'

class QuotaReservation < ApplicationRecord
  belongs_to :job

  TYPES = %w[discovery outreach].freeze
  STATUSES = %w[reserved consumed released expired].freeze

  validates :quota_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :amount, numericality: { greater_than: 0 }
  validates :reservation_key, presence: true, uniqueness: true
  validates :stat_date, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where(status: 'reserved').where('expires_at > ?', Time.current) }
  scope :expired_candidates, -> { where(status: 'reserved').where('expires_at <= ?', Time.current) }

  # Concurrency-safe quota reservation attempt
  def self.reserve!(job:, quota_type:, amount: 1, ttl: 10.minutes)
    stat_date = Time.current.in_time_zone(job.timezone).to_date
    daily_limit = quota_type == 'discovery' ? job.daily_discovery_target : job.daily_outreach_target

    job.with_lock do
      # Calculate consumed units for today
      stat = JobDailyStat.find_by(job_id: job.id, stat_date: stat_date)
      consumed = if quota_type == 'discovery'
                   stat&.unique_new_businesses || 0
                 else
                   stat&.outreach_confirmed || 0
                 end

      # Calculate active reserved units
      active_reserved = where(job_id: job.id, quota_type: quota_type, stat_date: stat_date)
                        .active
                        .sum(:amount)

      if (consumed + active_reserved + amount) > daily_limit
        return { success: false, message: "Daily #{quota_type} limit (#{daily_limit}) reached" }
      end

      reservation = create!(
        job:             job,
        quota_type:      quota_type,
        stat_date:       stat_date,
        amount:          amount,
        status:          'reserved',
        reservation_key: SecureRandom.uuid,
        expires_at:      ttl.from_now
      )

      { success: true, reservation: reservation }
    end
  end

  def consume!
    update!(status: 'consumed')
  end

  def release!
    update!(status: 'released')
  end

  def self.expire_stale_reservations!
    expired_candidates.update_all(status: 'expired', updated_at: Time.current)
  end
end

