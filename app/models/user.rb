# app/models/user.rb

# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :prospects, dependent: :destroy
  has_many :prospecting_profiles, dependent: :destroy
  has_many :searches, dependent: :destroy
  has_many :search_results, dependent: :destroy

  before_validation :downcase_email

  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :ai_tone, inclusion: { in: %w[Professional Friendly Casual Direct] }, allow_nil: true, if: -> { respond_to?(:ai_tone) }
  validates :ai_length, inclusion: { in: %w[Short Medium] }, allow_nil: true, if: -> { respond_to?(:ai_length) }

  def effective_ai_tone
    (respond_to?(:ai_tone) && ai_tone.presence) || 'Professional'
  end

  def effective_ai_length
    (respond_to?(:ai_length) && ai_length.presence) || 'Short'
  end

  private

  def downcase_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
