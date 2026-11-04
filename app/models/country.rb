# frozen_string_literal: true

class Country < ApplicationRecord
  has_many :country_cities, dependent: :restrict_with_error
  has_many :job_targets, dependent: :restrict_with_error

  CONSUMER_STATUSES = %w[widespread moderate limited unsupported].freeze
  BUSINESS_STATUSES = %w[available restricted unknown].freeze
  API_ELIGIBILITIES = %w[eligible restricted prohibited].freeze

  before_validation :normalize_codes

  validates :iso_country_code, presence: true,
                               uniqueness: { case_sensitive: false },
                               format: { with: /\A[A-Z]{2}\z/, message: 'must be an ISO 3166-1 alpha-2 code' }
  validates :iso_alpha3_code, presence: true,
                              uniqueness: { case_sensitive: false },
                              format: { with: /\A[A-Z]{3}\z/, message: 'must be an ISO 3166-1 alpha-3 code' }
  validates :name, presence: true
  validates :calling_code, presence: true, format: { with: /\A[0-9]{1,6}\z/, message: 'must be numbers only without +' }
  validates :default_timezone, presence: true
  validates :whatsapp_consumer_status, inclusion: { in: CONSUMER_STATUSES }
  validates :whatsapp_business_status, inclusion: { in: BUSINESS_STATUSES }
  validates :whatsapp_api_eligibility, inclusion: { in: API_ELIGIBILITIES }

  scope :active, -> { where(is_active: true) }

  def default_cities
    country_cities.active.default_pool.by_priority
  end

  private

  def normalize_codes
    self.iso_country_code = iso_country_code.to_s.strip.upcase if iso_country_code.present?
    self.iso_alpha3_code = iso_alpha3_code.to_s.strip.upcase if iso_alpha3_code.present?
    self.calling_code = calling_code.to_s.gsub(/\D/, '') if calling_code.present?
  end
end

