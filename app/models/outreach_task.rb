# frozen_string_literal: true

require 'digest'
require 'securerandom'

class OutreachTask < ApplicationRecord
  belongs_to :job
  belongs_to :job_prospect
  belongs_to :extension_device, optional: true
  has_one :prospect, through: :job_prospect

  STATUSES = %w[
    pending_review
    approved
    queued
    dispatched
    sending
    sent
    failed
    uncertain
    skipped
    cancelled
    retrying
  ].freeze

  TERMINAL_STATUSES = %w[sent failed skipped cancelled].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :prepared_message, presence: true
  validates :destination_phone, presence: true
  validates :whatsapp_url, presence: true
  validates :idempotency_key, presence: true, uniqueness: true
  validates :attempt_count, numericality: { greater_than_or_equal_to: 0 }
  validate :validate_job_prospect_matches_job
  validate :validate_device_user_ownership

  scope :pending_review, -> { where(status: 'pending_review') }
  scope :ready_for_dispatch, -> { where(status: %w[queued retrying]).where('scheduled_for <= ?', Time.current) }
  scope :active_in_flight, -> { where(status: %w[dispatched sending]) }
  scope :uncertain, -> { where(status: 'uncertain') }
  scope :sent, -> { where(status: 'sent') }

  # Generates an idempotent key for a given job and prospect
  def self.build_idempotency_key(job_id:, job_prospect_id:, round: 1)
    Digest::SHA256.hexdigest("outreach:#{job_id}:#{job_prospect_id}:round_#{round}")
  end

  # Atomically claim task for an extension device and generate a single-use token
  # Ensures the device does not already have an active task in-flight
  def claim_for_device!(device)
    raise ArgumentError, 'Device is required to claim a task' if device.nil?
    raise StandardError, 'Device is revoked' if device.revoked?

    self.class.transaction do
      # Concurrency lock on the task row
      lock!

      unless status.in?(%w[queued retrying])
        raise StandardError, "Cannot claim task with status '#{status}'"
      end

      # Device concurrency protection: One active in-flight task per device
      active_task_exists = self.class.where(extension_device_id: device.id, status: %w[dispatched sending]).exists?
      if active_task_exists
        raise StandardError, "Device '#{device.client_name || device.id}' already has an active outreach task in progress"
      end

      raw_token = SecureRandom.hex(32)
      token_digest = Digest::SHA256.hexdigest(raw_token)

      update!(
        status:                     'dispatched',
        extension_device:           device,
        dispatched_at:              Time.current,
        dispatch_token_digest:      token_digest,
        dispatch_token_expires_at:  5.minutes.from_now,
        attempt_count:              attempt_count + 1
      )

      raw_token
    end
  end

  def verify_dispatch_token(raw_token)
    return false if dispatch_token_digest.blank? || dispatch_token_expires_at.nil?
    return false if Time.current > dispatch_token_expires_at

    Digest::SHA256.hexdigest(raw_token.to_s) == dispatch_token_digest
  end

  def mark_sending!
    unless status == 'dispatched'
      raise StandardError, "Cannot transition to 'sending' from status '#{status}'"
    end

    update!(
      status:     'sending',
      sending_at: Time.current
    )
  end

  def mark_sent!
    unless status.in?(%w[dispatched sending])
      raise StandardError, "Cannot mark as sent from status '#{status}' (must be 'dispatched' or 'sending')"
    end

    update!(
      status:                     'sent',
      completed_at:               Time.current,
      dispatch_token_digest:      nil,
      dispatch_token_expires_at:  nil
    )
  end

  def mark_failed!(error_code: nil, error_details: nil)
    update!(
      status:                     'failed',
      completed_at:               Time.current,
      error_code:                 error_code,
      error_details:              error_details,
      dispatch_token_digest:      nil,
      dispatch_token_expires_at:  nil
    )
  end

  # Safety quarantine: an uncertain outcome must never be automatically retried
  def mark_uncertain!(error_details: nil)
    update!(
      status:                     'uncertain',
      error_code:                 'UNCERTAIN_DISPATCH_RESULT',
      error_details:              error_details,
      dispatch_token_digest:      nil,
      dispatch_token_expires_at:  nil
    )
  end

  private

  def validate_job_prospect_matches_job
    return if job_prospect.nil? || job.nil?

    if job_prospect.job_id != job_id
      errors.add(:job_prospect, 'must belong to the same Job as the OutreachTask')
    end
  end

  def validate_device_user_ownership
    return if extension_device.nil? || job.nil?

    if extension_device.user_id != job.user_id
      errors.add(:extension_device, 'must belong to the same user as the Job')
    end
  end
end

