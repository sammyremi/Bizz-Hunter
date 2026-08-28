# frozen_string_literal: true

module Locations
  class Countries < ApplicationService
    include HTTParty

    BASE_URL = 'https://countriesnow.space/api/v0.1/countries'

    def call
      response = self.class.get(BASE_URL)

      handle_response(response)
    end

    private

    def handle_response(response)
      return response.parsed_response if response.success?

      raise StandardError, 'Unable to retrieve countries'
    end
  end
end