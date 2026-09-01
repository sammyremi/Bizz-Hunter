# app/models/user.rb

# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :prospects, dependent: :destroy

  before_validation :downcase_email

  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  private

  def downcase_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
