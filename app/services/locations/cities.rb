# frozen_string_literal: true

module Locations
  class Cities < ApplicationService
    include HTTParty

    BASE_URL = 'https://countriesnow.space/api/v0.1/countries/state/cities'

    def initialize(country:, state:)
      @country = country
      @state = state
    end

    def call
      response = self.class.post(
        BASE_URL,
        headers: {
          'Content-Type' => 'application/json'
        },
        body: {
          country: country,
          state: state
        }.to_json
      )

      handle_response(response)
    end

    private

    attr_reader :country, :state

    def handle_response(response)
      return response.parsed_response if response.success?

      raise StandardError, 'Unable to retrieve cities'
    end
  end
end