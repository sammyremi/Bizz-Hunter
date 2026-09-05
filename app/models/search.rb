# app/models/search.rb

# frozen_string_literal: true

class Search < ApplicationRecord
  belongs_to :user, optional: true
  has_many :search_results, dependent: :destroy

  validates :business_type, presence: true

  scope :for_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }
end
