# app/controllers/concerns/prospecting_profiles_concern.rb

# frozen_string_literal: true

module ProspectingProfilesConcern
  extend ActiveSupport::Concern

  protected

  def prospecting_profile_params
    params.permit(
      :name,
      :service,
      :service_description,
      :is_default,
      target_businesses: [],
      opportunity_signals: [],
      contact_signals: []
    )
  end
end
