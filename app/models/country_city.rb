# frozen_string_literal: true

class CountryCity < ApplicationRecord
  belongs_to :country
  has_many :job_targets, dependent: :restrict_with_error

  CLASSIFICATIONS = %w[metropolis municipality urban_district settlement].freeze

  validates :name, presence: true
  validates :administrative_classification, inclusion: { in: CLASSIFICATIONS }
  validates :commercial_priority, numericality: { greater_than: 0 }
  validates :name, uniqueness: {
    scope: [:country_id, :state_or_region],
    case_sensitive: false,
    message: 'already exists in this country and region'
  }

  scope :active, -> { where(is_active: true) }
  scope :default_pool, -> { where(is_default_discovery_pool: true) }
  scope :by_priority, -> { order(commercial_priority: :asc, name: :asc) }
end

