# test/services/outreach_message_generator_test.rb

# frozen_string_literal: true

require 'test_helper'

class OutreachMessageGeneratorTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: 'outreach_test_user@example.com',
      password: 'Password123!',
      name: 'Outreach Tester',
      ai_tone: 'Professional',
      ai_length: 'Short'
    )

    @web_profile = ProspectingProfile.create!(
      user: @user,
      name: 'Web Dev Profile',
      service: 'Website Development',
      service_description: 'Building fast modern websites for local businesses',
      target_businesses: ['Restaurants'],
      opportunity_signals: ['No website'],
      contact_signals: ['Phone available']
    )

    @legal_profile = ProspectingProfile.create!(
      user: @user,
      name: 'Legal Services Profile',
      service: 'Legal Services',
      service_description: 'Providing commercial legal support and conveyancing',
      target_businesses: ['Real Estate Agencies'],
      opportunity_signals: ['Phone available'],
      contact_signals: ['Phone available']
    )

    @search_web = Search.create!(
      user: @user,
      prospecting_profile: @web_profile,
      business_type: 'restaurants',
      location_name: 'Lagos',
      query: 'restaurants in Lagos'
    )

    @search_result_web = SearchResult.create!(
      search: @search_web,
      user: @user,
      google_place_id: 'place_mama_kitchen',
      name: "Mama's Kitchen",
      business_type: 'restaurants',
      types: ['restaurant'],
      website: nil,
      phone: '+2348012345678',
      rating: 4.8,
      review_count: 150,
      opportunity_score: 92,
      opportunity_tier: 'high',
      opportunity_level: 'HIGH',
      opportunity_factors: ['Matches target', 'No website detected']
    )
  end

  test 'outreach_generator: builds encoded whatsapp url with personalized fallback when gemini client is unconfigured' do
    result = Ai::OutreachMessageGenerator.call(
      search_result: @search_result_web,
      user: @user
    )

    assert result[:success]
    assert_not_nil result[:data][:whatsapp_url]
    assert_includes result[:data][:whatsapp_url], 'https://wa.me/2348012345678?text='
    assert_equal "Mama's Kitchen", result[:data][:business_name]
    assert_equal '2348012345678', result[:data][:phone]

    msg = result[:data][:message]
    assert_not_nil msg
    refute msg.include?('score'), "Generated message must NEVER mention internal score"
    refute msg.include?('Bizz-Hunter'), "Generated message must NEVER mention Bizz-Hunter"
    refute msg.include?('tier'), "Generated message must NEVER mention internal tier"
  end

  test 'Test 1 & 2 — Search profile is authoritative: uses Search profile (Web Dev) instead of another user profile (Legal)' do
    result = Ai::OutreachMessageGenerator.call(
      search_result: @search_result_web,
      user: @user
    )

    assert result[:success]
    msg = result[:data][:message]
    assert (msg.downcase.include?('website') || msg.downcase.include?('site')), "Message should be about website development"
    refute msg.downcase.include?('legal'), "Must NOT use Legal Services when search profile is Website Development"
  end

  test 'Test 3 — Generic fallback for non-website service: Legal Services fallback does not mention websites' do
    search_legal = Search.create!(
      user: @user,
      prospecting_profile: @legal_profile,
      business_type: 'real estate',
      location_name: 'Abuja'
    )
    search_result_legal = SearchResult.create!(
      search: search_legal,
      user: @user,
      google_place_id: 'place_real_estate',
      name: 'Abuja Real Estate Expert',
      business_type: 'real estate',
      website: nil,
      phone: '+2348039999999'
    )

    result = Ai::OutreachMessageGenerator.call(
      search_result: search_result_legal,
      user: @user
    )

    assert result[:success]
    msg = result[:data][:message]
    assert (msg.downcase.include?('legal') || msg.downcase.include?('conveyancing')), "Message should be about legal services"
    refute msg.downcase.include?('website'), "Non-website service fallback MUST NOT mention websites"
    refute msg.include?('impressed by your work'), "Fallback MUST NOT contain unsupported praise"
  end

  test 'Test 4 — Website fallback: Website Development + blank website uses website fallback' do
    result = Ai::OutreachMessageGenerator.call(
      search_result: @search_result_web,
      user: @user
    )

    assert result[:success]
    msg = result[:data][:message]
    assert (msg.downcase.include?('website') || msg.downcase.include?('site')), "Message should mention website"
  end

  test 'Test 5 — Non-website service: Solar Installation + blank website does not mention website' do
    solar_profile = ProspectingProfile.create!(
      user: @user,
      name: 'Solar Profile',
      service: 'Solar Installation',
      service_description: 'Clean renewable energy setup for commercial properties',
      target_businesses: ['Hotels']
    )
    search_solar = Search.create!(
      user: @user,
      prospecting_profile: solar_profile,
      business_type: 'hotels',
      location_name: 'Lagos'
    )
    search_result_solar = SearchResult.create!(
      search: search_solar,
      user: @user,
      google_place_id: 'place_hotel_no_web',
      name: 'Lagos Grand Hotel',
      website: nil,
      phone: '+2348055555555'
    )

    result = Ai::OutreachMessageGenerator.call(
      search_result: search_result_solar,
      user: @user
    )

    assert result[:success]
    msg = result[:data][:message]
    assert (msg.downcase.include?('solar') || msg.include?('Solar Installation')), "Message should be about solar installation"
    refute msg.downcase.include?('website'), "Solar installation fallback MUST NOT mention websites"
  end

  test 'Test 6 — Unknown/present website: Website Development + website present does not claim no website' do
    search_result_with_web = SearchResult.create!(
      search: @search_web,
      user: @user,
      google_place_id: 'place_mama_web',
      name: "Mama's Kitchen Active",
      website: 'https://mamaskitchen.com',
      phone: '+2348012345678'
    )

    result = Ai::OutreachMessageGenerator.call(
      search_result: search_result_with_web,
      user: @user
    )

    assert result[:success]
    msg = result[:data][:message]
    refute msg.include?("don't currently have a website"), "Must NOT claim business lacks website when website is present"
  end

  test 'Test 7 — Missing profile or service: returns controlled validation error' do
    search_no_profile = Search.create!(
      user: @user,
      prospecting_profile: nil,
      business_type: 'restaurants',
      location_name: 'Abuja'
    )
    search_result_no_prof = SearchResult.create!(
      search: search_no_profile,
      user: @user,
      google_place_id: 'place_no_prof',
      name: 'No Profile Resto',
      phone: '+2348011111111'
    )

    result = Ai::OutreachMessageGenerator.call(
      search_result: search_result_no_prof,
      user: @user
    )

    refute result[:success]
    assert_includes result[:message], 'Prospecting Profile with a service is required'
  end
end
