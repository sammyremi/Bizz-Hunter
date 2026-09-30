# app/controllers/concerns/auth_concern.rb

# frozen_string_literal: true

module AuthConcern
  extend ActiveSupport::Concern

  protected

  def register_params
    # Rails' ParamsWrapper may wrap JSON body under :auth for AuthController.
    # Accept params from both the root level and the :auth wrapper.
    if params.key?(:auth)
      params.require(:auth).permit(:name, :email, :password)
    else
      params.permit(:name, :email, :password)
    end
  end

  def login_params
    if params.key?(:auth)
      params.require(:auth).permit(:email, :password)
    else
      params.permit(:email, :password)
    end
  end
end
