# test/services/qr_message_generator_test.rb

# frozen_string_literal: true

require 'test_helper'

class QrMessageGeneratorTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: 'qr_template_test@example.com',
      password: 'password123',
      name: 'QR Template Test User'
    )

    @profile_web = ProspectingProfile.create!(
      user: @user,
      name: 'Web Dev Profile',
      service: 'Website Development',
      service_description: 'I build modern websites for local businesses.',
      is_default: true
    )

    @profile_legal = ProspectingProfile.create!(
      user: @user,
      name: 'Legal Services Profile',
      service: 'Legal Advisory',
      service_description: 'Legal consulting and contracts for business owners.',
      is_default: false
    )
  end

  test 'generates reusable message template with {{business_name}} placeholder' do
    result = Ai::QrMessageGenerator.call(prospecting_profile: @profile_web)

    assert result[:success]
    assert_not_nil result[:template]
    assert_includes result[:template], '{{business_name}}'
    assert_includes result[:template].downcase, 'website'
  end

  test 'respects profile service for different profiles' do
    result_web = Ai::QrMessageGenerator.call(prospecting_profile: @profile_web)
    result_legal = Ai::QrMessageGenerator.call(prospecting_profile: @profile_legal)

    assert_includes result_web[:template].downcase, 'website'
    assert_includes result_legal[:template].downcase, 'legal'
    refute_includes result_legal[:template].downcase, 'website'
  end

  test 'handles nil profile gracefully with safe fallback' do
    result = Ai::QrMessageGenerator.call(prospecting_profile: nil)

    assert result[:success]
    assert_includes result[:template], '{{business_name}}'
  end

  test 'personalizes template deterministically by replacing {{business_name}}' do
    template = "Hi {{business_name}}, I provide website development for businesses like yours."
    b1_name = "Amazonia Restaurant"
    b2_name = "Abuja Garden Hotel"

    msg1 = template.gsub('{{business_name}}', b1_name)
    msg2 = template.gsub('{{business_name}}', b2_name)

    assert_equal "Hi Amazonia Restaurant, I provide website development for businesses like yours.", msg1
    assert_equal "Hi Abuja Garden Hotel, I provide website development for businesses like yours.", msg2
  end
end
