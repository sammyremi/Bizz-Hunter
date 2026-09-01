# app/controllers/concerns/locations_concern.rb

# frozen_string_literal: true

module LocationsConcern
  extend ActiveSupport::Concern

  protected

  def autocomplete_input_param
    params[:input].to_s.strip
  end

  def place_id_param
    params[:place_id].to_s.strip
  end
end
