# test/controllers/settings_controller_test.rb

# frozen_string_literal: true

require 'test_helper'

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: 'settings_test_user@example.com',
      password: 'Password123!',
      name: 'Settings User',
      ai_tone: 'Professional',
      ai_length: 'Short'
    )

    @token = JsonWebToken.encode(user_id: @user.id)
  end

  test 'GET /api/v1/settings requires authentication' do
    get '/api/v1/settings'
    assert_response :unauthorized
  end

  test 'GET /api/v1/settings returns current user preferences' do
    get '/api/v1/settings', headers: { 'Authorization' => "Bearer #{@token}" }
    assert_response :success
    json = JSON.parse(response.body)

    assert json['success']
    assert_equal 'Professional', json['data']['ai_tone']
    assert_equal 'Short', json['data']['ai_length']
  end

  test 'PATCH /api/v1/settings updates user AI preferences' do
    patch '/api/v1/settings',
          params: { ai_tone: 'Friendly', ai_length: 'Medium' },
          headers: { 'Authorization' => "Bearer #{@token}" }

    assert_response :success
    json = JSON.parse(response.body)

    assert json['success']
    assert_equal 'Friendly', json['data']['ai_tone']
    assert_equal 'Medium', json['data']['ai_length']

    @user.reload
    assert_equal 'Friendly', @user.ai_tone
    assert_equal 'Medium', @user.ai_length
  end

  test 'PATCH /api/v1/settings rejects invalid tone or length' do
    patch '/api/v1/settings',
          params: { ai_tone: 'InvalidTone' },
          headers: { 'Authorization' => "Bearer #{@token}" }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    refute json['success']
  end
end
