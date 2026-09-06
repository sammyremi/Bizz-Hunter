# test/services/prospecting_profiles/destroy_test.rb

# frozen_string_literal: true

require 'test_helper'

module ProspectingProfiles
  class DestroyTest < ActiveSupport::TestCase
    setup do
      @user = User.create!(name: 'User Destroy', email: 'destroy_test@example.com', password: 'password123')
      @profile = @user.prospecting_profiles.create!(
        name: 'Profile To Destroy',
        service: 'Web Dev',
        service_description: 'To be deleted.'
      )
    end

    test "deletes the specified profile" do
      result = ProspectingProfiles::Destroy.call(prospecting_profile: @profile)

      assert result[:success]
      assert_equal 'Prospecting profile deleted successfully', result[:message]
      assert_not ProspectingProfile.exists?(@profile.id)
    end
  end
end
