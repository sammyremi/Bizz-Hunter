# app/controllers/application_controller.rb

# frozen_string_literal: true

class ApplicationController < ActionController::API
  protected

  def authenticate_user!
    token = extract_token_from_header
    decoded = token ? JsonWebToken.decode(token) : nil

    if decoded && decoded[:user_id]
      @current_user = User.find_by(id: decoded[:user_id])
    end

    return if @current_user.present?

    render json: { success: false, message: 'Unauthorized. Please log in.' }, status: :unauthorized
  end

  def current_user
    @current_user
  end

  def authenticated?
    current_user.present?
  end

  private

  def extract_token_from_header
    header = request.headers['Authorization']
    return nil if header.blank?

    header.split(' ').last if header.start_with?('Bearer ')
  end
end
