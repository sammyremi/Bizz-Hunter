# frozen_string_literal: true

require 'digest'
require 'securerandom'

class ExtensionDevice < ApplicationRecord
  belongs_to :user
  has_many :outreach_tasks, dependent: :nullify

  STATUSES = %w[online busy paused offline revoked].freeze

  validates :device_uuid, presence: true, uniqueness: true
  validates :api_key_digest, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where.not(status: 'revoked') }
  scope :online, -> { where(status: %w[online busy]) }

  # Generates a raw API key, stores only its SHA-256 digest, and returns the raw key to show once to the user
  def self.register_device!(user:, client_name: nil, browser_name: 'Brave', os_name: nil, extension_version: nil)
    device_uuid = SecureRandom.uuid
    raw_secret  = SecureRandom.hex(24)
    raw_api_key = "bh_dev_#{device_uuid}_#{raw_secret}"

    device = create!(
      user:              user,
      device_uuid:       device_uuid,
      client_name:       client_name,
      browser_name:      browser_name,
      os_name:           os_name,
      extension_version: extension_version,
      api_key_digest:    Digest::SHA256.hexdigest(raw_api_key),
      status:            'online',
      registered_at:     Time.current,
      last_heartbeat_at: Time.current
    )

    { device: device, raw_api_key: raw_api_key }
  end

  def authenticate_api_key?(raw_key)
    return false if revoked?

    Digest::SHA256.hexdigest(raw_key.to_s) == api_key_digest
  end

  def heartbeat!
    update_columns(last_heartbeat_at: Time.current, status: (status == 'offline' ? 'online' : status))
  end

  def revoke!
    update!(status: 'revoked', revoked_at: Time.current)
  end

  def revoked?
    status == 'revoked' || revoked_at.present?
  end
end

