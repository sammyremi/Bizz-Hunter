# test/services/auth/security_services_test.rb

# frozen_string_literal: true

require 'test_helper'

module Auth
  class SecurityServicesTest < ActiveSupport::TestCase
    setup do
      @user = User.create!(
        name: 'Security User',
        email: 'security@example.com',
        password: 'Password123'
      )
    end

    test 'Auth::Register creates user and delivers verification email' do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        result = Auth::Register.call(
          name: 'New Registered User',
          email: 'newreg@example.com',
          password: 'StrongPassword123'
        )
        assert result[:success]
        assert_not_nil result[:token]
        assert_not result[:user].verified?
      end
    end

    test 'Auth::VerifyEmail verifies user with valid token' do
      token = @user.generate_verification_token!

      result = Auth::VerifyEmail.call(token: token)
      assert result[:success]

      @user.reload
      assert @user.verified?
    end

    test 'Auth::ResendVerification rate limits rapid requests' do
      @user.update_columns(verified_at: nil, verification_sent_at: Time.current)

      result = Auth::ResendVerification.call(user: @user)
      assert_not result[:success]
      assert_includes result[:error], 'Please wait a minute'
    end

    test 'Auth::ForgotPassword sends email and returns generic success' do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        result = Auth::ForgotPassword.call(email: 'security@example.com')
        assert result[:success]
        assert_includes result[:message], 'If an account exists'
      end
    end

    test 'Auth::ForgotPassword with non-existent email returns generic success to prevent enumeration' do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        result = Auth::ForgotPassword.call(email: 'nonexistent@example.com')
        assert result[:success]
        assert_includes result[:message], 'If an account exists'
      end
    end

    test 'Auth::ResetPassword updates password with valid token' do
      token = @user.generate_reset_password_token!

      result = Auth::ResetPassword.call(token: token, password: 'NewSecurePassword123')
      assert result[:success]

      @user.reload
      assert @user.authenticate('NewSecurePassword123')
    end

    test 'Auth::ChangePassword requires correct current password' do
      result = Auth::ChangePassword.call(
        user: @user,
        current_password: 'WrongPassword123',
        password: 'NewPassword123'
      )
      assert_not result[:success]
      assert_equal 'Incorrect current password.', result[:error]

      result_ok = Auth::ChangePassword.call(
        user: @user,
        current_password: 'Password123',
        password: 'NewPassword123'
      )
      assert result_ok[:success]

      @user.reload
      assert @user.authenticate('NewPassword123')
    end
  end
end
