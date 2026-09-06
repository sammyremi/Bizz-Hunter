# test/models/prospecting_profile_test.rb

# frozen_string_literal: true

require 'test_helper'

class ProspectingProfileTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: 'Profile Tester',
      email: 'profile_test@example.com',
      password: 'password123'
    )
  end

  test "1. prospecting profile belongs to user" do
    profile = @user.prospecting_profiles.build(
      name: 'Website Development for Restaurants',
      service: 'Website Development',
      service_description: 'I build modern responsive websites for local restaurants.'
    )
    assert profile.save
    assert_equal @user, profile.user
  end

  test "2. user has many prospecting_profiles" do
    p1 = @user.prospecting_profiles.create!(
      name: 'Web Dev',
      service: 'Website Development',
      service_description: 'Building custom websites.'
    )
    p2 = @user.prospecting_profiles.create!(
      name: 'SEO Service',
      service: 'SEO',
      service_description: 'Local search engine optimization.'
    )

    assert_includes @user.prospecting_profiles, p1
    assert_includes @user.prospecting_profiles, p2
    assert_equal 2, @user.prospecting_profiles.count
  end

  test "3. requires a name" do
    profile = @user.prospecting_profiles.build(
      name: nil,
      service: 'Website Development',
      service_description: 'Building websites.'
    )
    assert_not profile.valid?
    assert_includes profile.errors[:name], "can't be blank"
  end

  test "4. requires a service" do
    profile = @user.prospecting_profiles.build(
      name: 'Web Dev',
      service: nil,
      service_description: 'Building websites.'
    )
    assert_not profile.valid?
    assert_includes profile.errors[:service], "can't be blank"
  end

  test "5. requires a service_description" do
    profile = @user.prospecting_profiles.build(
      name: 'Web Dev',
      service: 'Website Development',
      service_description: nil
    )
    assert_not profile.valid?
    assert_includes profile.errors[:service_description], "can't be blank"
  end

  test "6. array/JSON fields store structured values correctly" do
    profile = @user.prospecting_profiles.create!(
      name: 'Restaurant Web Dev',
      service: 'Website Development',
      service_description: 'Building custom websites for hospitality.',
      target_businesses: ['restaurants', 'hotels', 'cafes'],
      opportunity_signals: ['no_website', 'outdated_website'],
      contact_signals: ['phone_available', 'whatsapp_available']
    )

    profile.reload
    assert_equal ['restaurants', 'hotels', 'cafes'], profile.target_businesses
    assert_equal ['no_website', 'outdated_website'], profile.opportunity_signals
    assert_equal ['phone_available', 'whatsapp_available'], profile.contact_signals
  end

  test "7. default value for is_default is false" do
    profile = @user.prospecting_profiles.create!(
      name: 'Default Test',
      service: 'SEO',
      service_description: 'SEO Optimization.'
    )
    assert_equal false, profile.is_default
  end

  test "8. dependent destroy removes profiles when user is deleted" do
    profile = @user.prospecting_profiles.create!(
      name: 'Orphan Test',
      service: 'Design',
      service_description: 'Graphic design.'
    )
    profile_id = profile.id

    @user.destroy
    assert_nil ProspectingProfile.find_by(id: profile_id)
  end
end
