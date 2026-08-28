# frozen_string_literal: true

module Locations
  class States < ApplicationService
    include HTTParty

    BASE_URL = 'https://countriesnow.space/api/v0.1/countries/states'

    def initialize(country:)
      @country = country
    end

    def call
      response = self.class.post(
        BASE_URL,
        headers: {
          'Content-Type' => 'application/json'
        },
        body: {
          country: country
        }.to_json
      )

      handle_response(response)
    end

    private

    attr_reader :country

    def handle_response(response)
      return response.parsed_response if response.success?

      raise StandardError, 'Unable to retrieve states'
    end
  end
end