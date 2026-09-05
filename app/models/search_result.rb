# app/models/search_result.rb

# frozen_string_literal: true

class SearchResult < ApplicationRecord
  belongs_to :search
  belongs_to :user, optional: true

  validates :name, presence: true
  validates :google_place_id, presence: true

  scope :for_user, ->(user) { where(user: user) }
  scope :no_website, -> { where("website IS NULL OR website = ''") }
  scope :has_website, -> { where("website IS NOT NULL AND website != ''") }
  scope :has_phone, -> { where("phone IS NOT NULL AND phone != '' OR national_phone IS NOT NULL AND national_phone != ''") }
  scope :high_opportunity, -> { where(opportunity_tier: 'high') }
  scope :medium_opportunity, -> { where(opportunity_tier: 'medium') }
  scope :low_opportunity, -> { where(opportunity_tier: 'low') }
end
