# app/controllers/concerns/auth_concern.rb

# frozen_string_literal: true

module AuthConcern
  extend ActiveSupport::Concern

  protected

  def register_params
    params.permit(:name, :email, :password)
  end

  def login_params
    params.permit(:email, :password)
  end
end
