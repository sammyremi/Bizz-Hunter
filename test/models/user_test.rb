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
end
