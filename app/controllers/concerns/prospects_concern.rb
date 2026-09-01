# app/controllers/concerns/prospects_concern.rb

# frozen_string_literal: true

module ProspectsConcern
  extend ActiveSupport::Concern

  protected

  def prospect_create_params
    params.permit(
      :google_place_id,
      :business_name,
      :category,
      :address,
      :latitude,
      :longitude,
      :rating,
      :review_count,
      :phone_number,
      :international_phone_number,
      :website,
      :google_maps_url,
      :status,
      :notes,
      :follow_up_at
    )
  end

  def prospect_update_params
    params.permit(
      :status,
      :notes,
      :follow_up_at,
      :phone_number,
      :website
    )
  end

  def filter_status_param
    params[:status].presence
  end
end
