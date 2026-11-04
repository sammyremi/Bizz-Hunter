# frozen_string_literal: true

class JobTarget < ApplicationRecord
  belongs_to :job
  belongs_to :country
  belongs_to :country_city, optional: true

  validates :category, presence: true
  validate :validate_city_presence
  validate :validate_catalog_city_matches_country

  scope :active, -> { where(is_active: true) }
  scope :unleased_or_expired, -> { where('lease_expires_at IS NULL OR lease_expires_at <= ?', Time.current) }
  scope :for_rotation, -> { order(Arel.sql('last_searched_at ASC NULLS FIRST, rotation_priority ASC, random()')) }

  # Lease a target safely with a TTL
  def lease!(ttl = 5.minutes)
    token = SecureRandom.hex(16)
    update_columns(
      lease_token:      token,
      leased_at:        Time.current,
      lease_expires_at: Time.current + ttl
    )
    token
  end

  # Renew lease: only succeeds if caller still holds the valid lease token
  def renew_lease!(token, ttl = 5.minutes)
    return false if token.blank?

    rows_updated = self.class.where(id: id, lease_token: token)
                             .where('lease_expires_at > ?', Time.current)
                             .update_all(
                               leased_at:        Time.current,
                               lease_expires_at: Time.current + ttl
                             )

    rows_updated > 0
  end

  # Fenced release: only clears lease if caller holds the matching token
  def release_lease!(token = nil)
    scope = self.class.where(id: id)
    scope = scope.where(lease_token: token) if token.present?
    scope.update_all(lease_token: nil, leased_at: nil, lease_expires_at: nil)
  end

  # Fenced completion: only updates outcome and clears lease if caller still holds the active token
  def record_search_outcome!(token:, discovered_count:)
    return false if token.blank?

    # Atomic fenced update
    rows_updated = self.class.where(id: id, lease_token: token)
                             .update_all([
                               'search_count = search_count + 1, ' \
                               'total_discovered_count = total_discovered_count + ?, ' \
                               'last_searched_at = ?, ' \
                               'lease_token = NULL, leased_at = NULL, lease_expires_at = NULL',
                               discovered_count,
                               Time.current
                             ])

    rows_updated > 0
  end

  def city_name
    country_city&.name || custom_city_name
  end

  def region_name
    country_city&.state_or_region || custom_region_name
  end

  private

  def validate_city_presence
    if country_city_id.present? && custom_city_name.present?
      errors.add(:base, 'A target cannot have both a catalog city and a custom city name')
    elsif country_city_id.blank? && custom_city_name.blank?
      errors.add(:base, 'A catalog city or custom city name must be provided')
    end
  end

  def validate_catalog_city_matches_country
    return if country_city.nil? || country.nil?

    if country_city.country_id != country_id
      errors.add(:country_city, 'must belong to the selected country')
    end
  end
end

