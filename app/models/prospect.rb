# app/models/prospect.rb

# frozen_string_literal: true

class Prospect < ApplicationRecord
  STATUSES = %w[NEW CONTACTED INTERESTED CONVERTED NOT_INTERESTED].freeze

  belongs_to :user

  validates :business_name, presence: true
  validates :google_place_id, presence: true,
                              uniqueness: { scope: :user_id, message: 'has already been saved to your prospects' }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(updated_at: :desc) }
end
