# test/mailers/user_mailer_test.rb
# frozen_string_literal: true

require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test 'verification_email' do
    user = User.new(email: 'user@example.com')
    mail = UserMailer.verification_email(user, 'test_token')

    assert_equal 'Verify your Bizz-Hunter email address', mail.subject
    assert_equal ['user@example.com'], mail.to
    assert_equal ['onboarding@resend.dev'], mail.from
    assert_includes mail.body.encoded, 'test_token'
  end

  test 'password_reset_email' do
    user = User.new(email: 'user@example.com')
    mail = UserMailer.password_reset_email(user, 'reset_token')

    assert_equal 'Reset your Bizz-Hunter password', mail.subject
    assert_equal ['user@example.com'], mail.to
    assert_equal ['onboarding@resend.dev'], mail.from
    assert_includes mail.body.encoded, 'reset_token'
  end
end
