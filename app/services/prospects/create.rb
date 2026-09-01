# app/services/prospects/create.rb

# frozen_string_literal: true

module Prospects
  class Create < ApplicationService
    def initialize(user:, params:)
      @user = user
      @params = params
    end

    def call
      google_place_id = params[:google_place_id].to_s.strip

      if google_place_id.blank?
        return {
          success: false,
          prospect: nil,
          status: :bad_request,
          message: 'google_place_id is required'
        }
      end

      prospect = user.prospects.find_or_initialize_by(google_place_id: google_place_id)
      prospect.assign_attributes(params)

      if prospect.save
        {
          success: true,
          prospect: prospect,
          status: :created,
          message: 'Prospect saved successfully'
        }
      else
        {
          success: false,
          prospect: nil,
          status: :unprocessable_entity,
          message: prospect.errors.full_messages.join(', ')
        }
      end
    end

    private

    attr_reader :user, :params
  end
end
