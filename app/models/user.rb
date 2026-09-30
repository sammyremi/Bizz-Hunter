# app/models/user.rb

# frozen_string_literal: true

require 'digest'
require 'securerandom'

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

  # Password validation for non-OAuth users or password changes
  validates :password, presence: true, if: :password_required?
  validate :enforce_strong_password_policy, if: :password_required_or_present?

  validates :ai_tone, inclusion: { in: %w[Professional Friendly Casual Direct] }, allow_nil: true, if: -> { respond_to?(:ai_tone) }
  validates :ai_length, inclusion: { in: %w[Short Medium] }, allow_nil: true, if: -> { respond_to?(:ai_length) }

  def verified?
    verified_at.present?
  end

  def effective_ai_tone
    (respond_to?(:ai_tone) && ai_tone.presence) || 'Professional'
  end

  def effective_ai_length
    (respond_to?(:ai_length) && ai_length.presence) || 'Short'
  end

  # Generate single-use, expiring email verification token
  def generate_verification_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update_columns(
      verification_token_digest: Digest::SHA256.hexdigest(raw_token),
      verification_sent_at: Time.current
    )
    raw_token
  end

  # Confirm email using raw verification token
  def self.verify_email(raw_token)
    return { success: false, error: 'Token is required.' } if raw_token.blank?

    digest = Digest::SHA256.hexdigest(raw_token.to_s)
    user = find_by(verification_token_digest: digest)

    unless user
      return { success: false, error: 'Invalid or expired verification token.' }
    end

    if user.verification_sent_at.nil? || user.verification_sent_at < 24.hours.ago
      return { success: false, error: 'Verification link has expired. Please request a new one.' }
    end

    user.update!(
      verified_at: Time.current,
      verification_token_digest: nil,
      verification_sent_at: nil
    )

    { success: true, user: user }
  end

  # Generate single-use, expiring password reset token
  def generate_reset_password_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update_columns(
      reset_password_token_digest: Digest::SHA256.hexdigest(raw_token),
      reset_password_sent_at: Time.current
    )
    raw_token
  end

  # Reset password using raw reset token
  def self.reset_password_with_token(raw_token, new_password)
    return { success: false, error: 'Token is required.' } if raw_token.blank?

    digest = Digest::SHA256.hexdigest(raw_token.to_s)
    user = find_by(reset_password_token_digest: digest)

    unless user
      return { success: false, error: 'Invalid or expired password reset token.' }
    end

    if user.reset_password_sent_at.nil? || user.reset_password_sent_at < 1.hour.ago
      return { success: false, error: 'Password reset link has expired. Please request a new one.' }
    end

    user.password = new_password
    unless user.valid?
      return { success: false, error: user.errors.full_messages.join(', ') }
    end

    # Save password and clear single-use reset token immediately
    user.reset_password_token_digest = nil
    user.reset_password_sent_at = nil
    user.save!

    { success: true, user: user }
  end

  # Find or create user via Google OAuth (automatically verified)
  def self.find_or_create_from_google(google_profile)
    uid   = google_profile[:uid].to_s
    email = google_profile[:email].to_s.strip.downcase
    name  = google_profile[:name].to_s.strip.presence || email.split('@').first
    avatar_url = google_profile[:avatar_url]

    # 1. Exact match on provider + uid (returning user via Google)
    user = find_by(provider: 'google', uid: uid)
    if user
      user.update_columns(verified_at: Time.current) unless user.verified?
      return user
    end

    # 2. Existing email/password account — link Google to it
    user = find_by(email: email)
    if user
      user.update_columns(provider: 'google', uid: uid, avatar_url: avatar_url, verified_at: Time.current)
      return user
    end

    # 3. Brand-new user — create without a password, verified by Google
    create!(
      provider:   'google',
      uid:        uid,
      email:      email,
      name:       name,
      avatar_url: avatar_url,
      password_digest: nil,
      verified_at: Time.current
    )
  end

  private

  def password_required?
    provider.blank? && (new_record? || password.present?)
  end

  def password_required_or_present?
    password_required? || password.present?
  end

  def enforce_strong_password_policy
    return if password.blank?

    errors.add(:password, 'must be at least 8 characters long') if password.length < 8
    errors.add(:password, 'must contain at least one lowercase letter') unless password.match?(/[a-z]/)
    errors.add(:password, 'must contain at least one uppercase letter') unless password.match?(/[A-Z]/)
    errors.add(:password, 'must contain at least one number') unless password.match?(/\d/)
  end

  def downcase_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
