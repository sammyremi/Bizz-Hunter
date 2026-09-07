# app/services/prospecting_profiles/destroy.rb

# frozen_string_literal: true

module ProspectingProfiles
  class Destroy < ApplicationService
    def initialize(prospecting_profile:)
      @prospecting_profile = prospecting_profile
    end

    def call
      prospecting_profile.destroy
      {
        success: true,
        message: 'Prospecting profile deleted successfully'
      }
    end

    private

    attr_reader :prospecting_profile
  end
end
