# app/controllers/concerns/business_discovery_concern.rb

# frozen_string_literal: true

module BusinessDiscoveryConcern
  protected

  def business_discovery_params
    params.permit(
      :business_type,
      :country,
      :state,
      :city,
      :area,
      :min_rating,
      :has_phone,
      :has_website
    )
  end
end