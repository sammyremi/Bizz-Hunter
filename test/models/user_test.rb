# test/models/user_test.rb

# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "valid user saves with downcased email and password digest" do
    user = User.new(
      name: 'Samuel Adebayo',
      email: 'SAMUEL_UNIQUE@EXAMPLE.COM',
      password: 'password123'
    )
    assert user.save
    assert_equal 'samuel_unique@example.com', user.email
    assert user.authenticate('password123')
  end

  test "requires name, email, and password" do
    user = User.new
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
    assert_includes user.errors[:email], "can't be blank"
  end

  test "enforces unique email case-insensitively" do
    User.create!(name: 'User One', email: 'test_uniq@example.com', password: 'password123')
    duplicate = User.new(name: 'User Two', email: 'TEST_UNIQ@EXAMPLE.COM', password: 'password123')

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], 'has already been taken'
  end

  # --- Google OAuth tests ---

  test "find_or_create_from_google creates a new user from Google profile" do
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
      assert_equal 'newgoogleuser@example.com', user.email
      assert_equal 'New Google User', user.name
      assert_equal 'https://example.com/avatar.jpg', user.avatar_url
      assert_nil user.password_digest
    end
  end

  test "find_or_create_from_google returns existing user on repeated Google sign-in" do
    profile = { uid: 'google_uid_002', email: 'returning@example.com', name: 'Returning User', avatar_url: nil }

    first_user = User.find_or_create_from_google(profile)

    assert_no_difference 'User.count' do
      second_user = User.find_or_create_from_google(profile)
      assert_equal first_user.id, second_user.id
    end
  end

  test "find_or_create_from_google links Google to existing email/password account" do
    existing = User.create!(name: 'Existing User', email: 'linked@example.com', password: 'password123')

    profile = { uid: 'google_uid_003', email: 'linked@example.com', name: 'Existing User', avatar_url: nil }

    assert_no_difference 'User.count' do
      linked_user = User.find_or_create_from_google(profile)
      assert_equal existing.id, linked_user.id
      assert_equal 'google', linked_user.provider
      assert_equal 'google_uid_003', linked_user.uid
    end
  end

  test "Google OAuth user is valid without a password" do
    user = User.new(
      name:     'OAuth User',
      email:    'oauth@example.com',
      provider: 'google',
      uid:      'google_uid_004'
    )
    assert user.valid?, user.errors.full_messages.to_s
  end

  test "email/password user requires a password" do
    user = User.new(name: 'Password User', email: 'pwuser@example.com')
    assert_not user.valid?
    assert user.errors[:password].any?
  end
end

