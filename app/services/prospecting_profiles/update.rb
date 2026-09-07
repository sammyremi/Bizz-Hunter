# app/services/prospecting_profiles/update.rb

# frozen_string_literal: true

module ProspectingProfiles
  class Update < ApplicationService
    def initialize(prospecting_profile:, params:)
      @prospecting_profile = prospecting_profile
      @params = params
    end

    def call
      if prospecting_profile.update(params)
        handle_default_flag(prospecting_profile)
        {
          success: true,
          profile: prospecting_profile,
          message: 'Prospecting profile updated successfully'
        }
      else
        {
          success: false,
          profile: nil,
          errors: prospecting_profile.errors.to_hash,
          message: 'Validation failed'
        }
      end
    end

    private

    attr_reader :prospecting_profile, :params

    def handle_default_flag(profile)
      return unless profile.is_default?

      profile.user.prospecting_profiles.where.not(id: profile.id).where(is_default: true).update_all(is_default: false)
    end
  end
end
