# app/services/prospects/update.rb

# frozen_string_literal: true

module Prospects
  class Update < ApplicationService
    def initialize(prospect:, params:)
      @prospect = prospect
      @params = params
    end

    def call
      if prospect.update(params)
        {
          success: true,
          prospect: prospect,
          message: 'Prospect updated successfully'
        }
      else
        {
          success: false,
          prospect: nil,
          message: prospect.errors.full_messages.join(', ')
        }
      end
    end

    private

    attr_reader :prospect, :params
  end
end
