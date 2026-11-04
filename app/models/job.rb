# frozen_string_literal: true

class Job < ApplicationRecord
  belongs_to :user
  belongs_to :prospecting_profile, optional: true

  has_many :job_targets, dependent: :destroy
  has_many :job_prospects, dependent: :destroy
  has_many :prospects, through: :job_prospects
  # Restrict deletion if historical outreach tasks exist, preserving outreach audit trails
  has_many :outreach_tasks, dependent: :restrict_with_error
  has_many :job_daily_stats, dependent: :destroy
  has_many :quota_reservations, dependent: :destroy

  STATUSES = %w[draft active paused completed archived].freeze
  OUTREACH_MODES = %w[manual_review automatic].freeze
  WEBSITE_TARGETING = %w[no_website weak_or_outdated both].freeze

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :outreach_mode, inclusion: { in: OUTREACH_MODES }
  validates :website_targeting, inclusion: { in: WEBSITE_TARGETING }
  validates :daily_discovery_target, numericality: { greater_than: 0, less_than_or_equal_to: 500 }
  validates :daily_outreach_target, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :outreach_interval_seconds, numericality: { greater_than_or_equal_to: 60 }
  validates :message_template, presence: true
  validate :validate_active_weekdays
  validate :validate_prospecting_profile_ownership

  scope :active, -> { where(status: 'active') }
  scope :paused, -> { where(status: 'paused') }
  scope :archived, -> { where(status: 'archived') }
  scope :unarchived, -> { where.not(status: 'archived') }

  def archive!
    update!(status: 'archived', archived_at: Time.current)
  end

  def archived?
    status == 'archived' || archived_at.present?
  end

  # Checks if the job is eligible to run discovery right now in its configured timezone and schedule
  def eligible_for_discovery_at?(time = Time.current)
    return false unless status == 'active'
    return false if archived?

    # Resolve local time in the Job's timezone
    local_time = time.in_time_zone(timezone)
    cwday = local_time.wday == 0 ? 7 : local_time.wday # Convert Sunday=0 to Sunday=7

    return false unless active_weekdays.include?(cwday)

    # Check window times (converted to seconds from midnight)
    current_sec = local_time.seconds_since_midnight
    start_sec   = discovery_window_start.seconds_since_midnight
    end_sec     = discovery_window_end.seconds_since_midnight

    if start_sec <= end_sec
      current_sec >= start_sec && current_sec <= end_sec
    else
      # Spans midnight (e.g. 22:00 to 06:00)
      current_sec >= start_sec || current_sec <= end_sec
    end
  end

  private

  def validate_active_weekdays
    return errors.add(:active_weekdays, 'must not be empty') if active_weekdays.blank?

    unless active_weekdays.is_a?(Array) && active_weekdays.all? { |d| d.is_a?(Integer) && d.between?(1, 7) }
      errors.add(:active_weekdays, 'must only contain integers between 1 (Monday) and 7 (Sunday)')
    end
  end

  def validate_prospecting_profile_ownership
    return if prospecting_profile.nil?

    if prospecting_profile.user_id != user_id
      errors.add(:prospecting_profile, 'must belong to the same user as the Job')
    end
  end
end

