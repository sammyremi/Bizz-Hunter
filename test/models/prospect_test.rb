# test/models/prospect_test.rb

# frozen_string_literal: true

require 'test_helper'

class ProspectTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: 'Tester', email: 'prospect_test@example.com', password: 'password123')
  end

  test "valid prospect belongs to user" do
    prospect = @user.prospects.build(
      google_place_id: 'ChIJ123',
      business_name: 'Abuja Cafe',
      status: 'NEW'
    )
    assert prospect.save
  end

  test "enforces google_place_id uniqueness per user" do
    @user.prospects.create!(google_place_id: 'ChIJ123', business_name: 'Abuja Cafe', status: 'NEW')
    duplicate = @user.prospects.build(google_place_id: 'ChIJ123', business_name: 'Abuja Cafe Copy', status: 'NEW')

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:google_place_id], 'has already been saved to your prospects'
  end

  test "allows same google_place_id for different users" do
    user_two = User.create!(name: 'Tester 2', email: 'prospect_test2@example.com', password: 'password123')
    @user.prospects.create!(google_place_id: 'ChIJ123', business_name: 'Abuja Cafe', status: 'NEW')

    other_prospect = user_two.prospects.build(google_place_id: 'ChIJ123', business_name: 'Abuja Cafe', status: 'NEW')
    assert other_prospect.valid?
  end

  test "validates status inclusion" do
    invalid_prospect = @user.prospects.build(google_place_id: 'ChIJ456', business_name: 'Test', status: 'INVALID_STATUS')
    assert_not invalid_prospect.valid?
  end
end
