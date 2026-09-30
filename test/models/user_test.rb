# test/models/user_test.rb

# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "valid user saves with downcased email and password digest" do
    user = User.new(
      name: 'Samuel Adebayo',
      email: 'SAMUEL_UNIQUE@EXAMPLE.COM',
      password: 'Password123'
    )
    assert user.save
    assert_equal 'samuel_unique@example.com', user.email
    assert user.authenticate('Password123')
  end

  test "requires name, email, and password" do
    user = User.new
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
    assert_includes user.errors[:email], "can't be blank"
  end

  test "enforces unique email case-insensitively" do
    User.create!(name: 'User One', email: 'test_uniq@example.com', password: 'Password123')
    duplicate = User.new(name: 'User Two', email: 'TEST_UNIQ@EXAMPLE.COM', password: 'Password123')

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], 'has already been taken'
  end

  # --- Strong Password Policy Tests ---

  test "rejects passwords shorter than 8 characters" do
    user = User.new(name: 'Short PW', email: 'short@example.com', password: 'Pass12')
    assert_not user.valid?
    assert_includes user.errors[:password], 'must be at least 8 characters long'
  end

  test "rejects passwords missing lowercase letter" do
    user = User.new(name: 'No Lower', email: 'nolower@example.com', password: 'PASSWORD123')
    assert_not user.valid?
    assert_includes user.errors[:password], 'must contain at least one lowercase letter'
  end

  test "rejects passwords missing uppercase letter" do
    user = User.new(name: 'No Upper', email: 'noupper@example.com', password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:password], 'must contain at least one uppercase letter'
  end

  test "rejects passwords missing number" do
    user = User.new(name: 'No Number', email: 'nonumber@example.com', password: 'PasswordWord')
    assert_not user.valid?
    assert_includes user.errors[:password], 'must contain at least one number'
  end

  test "accepts valid strong password" do
    user = User.new(name: 'Strong PW', email: 'strong@example.com', password: 'SecurePassword123')
    assert user.valid?, user.errors.full_messages.to_s
  end

  # --- Email Verification Tests ---

  test "generate_verification_token! stores digest and returns raw token" do
    user = User.create!(name: 'Verify Test', email: 'verify1@example.com', password: 'Password123')
    raw_token = user.generate_verification_token!

    assert_not_nil raw_token
    assert_not_equal raw_token, user.verification_token_digest
    assert_equal Digest::SHA256.hexdigest(raw_token), user.verification_token_digest
    assert_not_nil user.verification_sent_at
  end

  test "verify_email succeeds with valid raw token and marks user verified" do
    user = User.create!(name: 'Verify Test', email: 'verify2@example.com', password: 'Password123')
    raw_token = user.generate_verification_token!

    result = User.verify_email(raw_token)
    assert result[:success]

    user.reload
    assert user.verified?
    assert_nil user.verification_token_digest
  end

  # --- Password Reset Tests ---

  test "generate_reset_password_token! stores digest and returns raw token" do
    user = User.create!(name: 'Reset Test', email: 'reset1@example.com', password: 'Password123')
    raw_token = user.generate_reset_password_token!

    assert_not_nil raw_token
    assert_equal Digest::SHA256.hexdigest(raw_token), user.reset_password_token_digest
    assert_not_nil user.reset_password_sent_at
  end

  test "reset_password_with_token updates password and invalidates token" do
    user = User.create!(name: 'Reset Test', email: 'reset2@example.com', password: 'OldPassword123')
    raw_token = user.generate_reset_password_token!

    result = User.reset_password_with_token(raw_token, 'NewPassword123')
    assert result[:success]

    user.reload
    assert user.authenticate('NewPassword123')
    assert_nil user.reset_password_token_digest
  end

  # --- Google OAuth tests ---

  test "find_or_create_from_google creates a new verified user from Google profile" do
    profile = {
      uid:        'google_uid_001',
      email:      'newgoogleuser@example.com',
      name:       'New Google User',
      avatar_url: 'https://example.com/avatar.jpg'
    }

    assert_difference 'User.count', 1 do
      user = User.find_or_create_from_google(profile)
      assert_equal 'google', user.provider
      assert_equal 'google_uid_001', user.uid
      assert user.verified?
      assert_nil user.password_digest
    end
  end
end
