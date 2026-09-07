# test/services/prospecting_profiles/create_test.rb

# frozen_string_literal: true

require 'test_helper'

module ProspectingProfiles
  class CreateTest < ActiveSupport::TestCase
    setup do
      @user_a = User.create!(name: 'User A', email: 'service_a@example.com', password: 'password123')
      @user_b = User.create!(name: 'User B', email: 'service_b@example.com', password: 'password123')
    end

    test "creates a profile associated with user" do
      result = ProspectingProfiles::Create.call(
        user: @user_a,
        params: {
          name: 'Web Dev Service',
          service: 'Website Development',
          service_description: 'Building custom websites.'
        }
      )

      assert result[:success]
      assert_equal @user_a, result[:profile].user
      assert_equal 'Web Dev Service', result[:profile].name
    end

    test "returns errors on invalid attributes" do
      result = ProspectingProfiles::Create.call(
        user: @user_a,
        params: { name: '', service: '', service_description: '' }
      )

      assert_not result[:success]
      assert_nil result[:profile]
      assert result[:errors].key?(:name)
    end

    test "setting profile as default clears default flag on user A's other profiles without affecting user B" do
      old_default_a = @user_a.prospecting_profiles.create!(
        name: 'Old Default A',
        service: 'SEO',
        service_description: 'Old SEO Service',
        is_default: true
      )

      profile_b = @user_b.prospecting_profiles.create!(
        name: 'Profile B Default',
        service: 'Design',
        service_description: 'Design for B',
        is_default: true
      )

      new_default_a = ProspectingProfiles::Create.call(
        user: @user_a,
        params: {
          name: 'New Default A',
          service: 'Web Dev',
          service_description: 'New Web Dev Service',
          is_default: true
        }
      )[:profile]

      assert new_default_a.is_default
      assert_not old_default_a.reload.is_default, "User A's old default should be set to false"
      assert profile_b.reload.is_default, "User B's default status should be completely untouched"
    end
  end
end
