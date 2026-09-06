# test/services/prospecting_profiles/update_test.rb

# frozen_string_literal: true

require 'test_helper'

module ProspectingProfiles
  class UpdateTest < ActiveSupport::TestCase
    setup do
      @user_a = User.create!(name: 'User A', email: 'update_a@example.com', password: 'password123')
      @user_b = User.create!(name: 'User B', email: 'update_b@example.com', password: 'password123')

      @profile_a1 = @user_a.prospecting_profiles.create!(
        name: 'Profile A1',
        service: 'Web Dev',
        service_description: 'Description A1',
        is_default: true
      )

      @profile_a2 = @user_a.prospecting_profiles.create!(
        name: 'Profile A2',
        service: 'SEO',
        service_description: 'Description A2',
        is_default: false
      )

      @profile_b1 = @user_b.prospecting_profiles.create!(
        name: 'Profile B1',
        service: 'Design',
        service_description: 'Description B1',
        is_default: true
      )
    end

    test "updates profile attributes successfully" do
      result = ProspectingProfiles::Update.call(
        prospecting_profile: @profile_a2,
        params: { name: 'Updated Profile A2' }
      )

      assert result[:success]
      assert_equal 'Updated Profile A2', @profile_a2.reload.name
    end

    test "fails gracefully on invalid update params" do
      result = ProspectingProfiles::Update.call(
        prospecting_profile: @profile_a2,
        params: { name: '' }
      )

      assert_not result[:success]
      assert result[:errors].key?(:name)
    end

    test "updating is_default to true updates user A's other profiles without altering user B" do
      result = ProspectingProfiles::Update.call(
        prospecting_profile: @profile_a2,
        params: { is_default: true }
      )

      assert result[:success]
      assert @profile_a2.reload.is_default
      assert_not @profile_a1.reload.is_default, "User A's old default should be false"
      assert @profile_b1.reload.is_default, "User B's default profile should remain untouched"
    end
  end
end
