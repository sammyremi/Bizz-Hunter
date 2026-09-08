# app/models/prospecting_profile.rb

# frozen_string_literal: true

class ProspectingProfile < ApplicationRecord
  belongs_to :user
  has_many :searches, dependent: :nullify

  before_validation :normalize_array_fields

  validates :name, presence: true
  validates :service, presence: true
  validates :service_description, presence: true

  private

  def normalize_array_fields
    self.target_businesses = Array(target_businesses) if target_businesses.present?
    self.target_businesses ||= []

    self.opportunity_signals = Array(opportunity_signals) if opportunity_signals.present?
    self.opportunity_signals ||= []

    self.contact_signals = Array(contact_signals) if contact_signals.present?
    self.contact_signals ||= []
  end
end
