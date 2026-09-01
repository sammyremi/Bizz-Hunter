# app/services/prospects/destroy.rb

# frozen_string_literal: true

module Prospects
  class Destroy < ApplicationService
    def initialize(prospect:)
      @prospect = prospect
    end

    def call
      prospect.destroy
      {
        success: true,
        message: 'Prospect removed successfully'
      }
    end

    private

    attr_reader :prospect
  end
end
