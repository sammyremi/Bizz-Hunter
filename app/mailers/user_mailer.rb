# app/mailers/user_mailer.rb
# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: -> { default_sender }

  def verification_email(user, token)
    @user = user
    @token = token
    @verify_url = "#{frontend_root_url}#verify_email=#{token}"

    mail(to: @user.email, subject: 'Verify your Bizz-Hunter email address')
  end

  def password_reset_email(user, token)
    @user = user
    @token = token
    @reset_url = "#{frontend_root_url}#reset_password_token=#{token}"

    mail(to: @user.email, subject: 'Reset your Bizz-Hunter password')
  end

  private

  def default_sender
    return ENV['MAIL_FROM'] if ENV['MAIL_FROM'].present?
    return ENV['RESEND_FROM'] if ENV['RESEND_FROM'].present?

    'onboarding@resend.dev'
  end

  def frontend_root_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:4000/')
  end
end
