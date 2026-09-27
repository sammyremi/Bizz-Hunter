# app/models/user.rb

# frozen_string_literal: true

class User < ApplicationRecord
  # password_digest is nullable for Google-only accounts
  has_secure_password validations: false

  has_many :prospects, dependent: :destroy
  has_many :prospecting_profiles, dependent: :destroy
  has_many :searches, dependent: :destroy
  has_many :search_results, dependent: :destroy

  before_validation :downcase_email

  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  # Password is required only for users who are NOT using an OAuth provider
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :ai_tone, inclusion: { in: %w[Professional Friendly Casual Direct] }, allow_nil: true, if: -> { respond_to?(:ai_tone) }
  validates :ai_length, inclusion: { in: %w[Short Medium] }, allow_nil: true, if: -> { respond_to?(:ai_length) }

  def effective_ai_tone
    (respond_to?(:ai_tone) && ai_tone.presence) || 'Professional'
  end

  def effective_ai_length
    (respond_to?(:ai_length) && ai_length.presence) || 'Short'
  end

  # Find an existing user by Google provider+uid, or create a new one from
  # the verified Google profile. If a user already exists with the same email
  # (email/password signup), we link the Google account to that user.
  def self.find_or_create_from_google(google_profile)
    uid   = google_profile[:uid].to_s
    email = google_profile[:email].to_s.strip.downcase
    name  = google_profile[:name].to_s.strip.presence || email.split('@').first
    avatar_url = google_profile[:avatar_url]

    # 1. Exact match on provider + uid (returning user via Google)
    user = find_by(provider: 'google', uid: uid)
    return user if user

    # 2. Existing email/password account — link Google to it
    user = find_by(email: email)
    if user
      user.update_columns(provider: 'google', uid: uid, avatar_url: avatar_url)
      return user
    end

    # 3. Brand-new user — create without a password
    create!(
      provider:   'google',
      uid:        uid,
      email:      email,
      name:       name,
      avatar_url: avatar_url,
      password_digest: nil
    )
  end

  private

  def password_required?
    provider.blank? && (new_record? || password.present?)
  end

  def downcase_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
