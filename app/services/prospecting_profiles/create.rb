# app/services/prospecting_profiles/create.rb

# frozen_string_literal: true

module ProspectingProfiles
  class Create < ApplicationService
    def initialize(user:, params:)
      @user = user
      @params = params
    end

    def call
      profile = user.prospecting_profiles.build(params)

      if profile.save
        handle_default_flag(profile)
        {
          success: true,
          profile: profile,
          message: 'Prospecting profile created successfully'
        }
      else
        {
          success: false,
          profile: nil,
          errors: profile.errors.to_hash,
          message: 'Validation failed'
        }
      end
    end

    private

    attr_reader :user, :params

    def handle_default_flag(profile)
      return unless profile.is_default?

      user.prospecting_profiles.where.not(id: profile.id).where(is_default: true).update_all(is_default: false)
    end
  end
end
