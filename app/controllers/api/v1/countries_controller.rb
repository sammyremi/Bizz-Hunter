# frozen_string_literal: true

# app/controllers/api/v1/countries_controller.rb
module Api
  module V1
    class CountriesController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/countries
      def index
        countries = Country.active.order(name: :asc)
        render json: {
          success: true,
          data: countries.map { |c| format_country(c) }
        }, status: :ok
      end

      # GET /api/v1/countries/:id_or_code/cities
      def cities
        country = Country.active.find_by('id::text = :val OR iso_country_code = :code',
                                         val: params[:id], code: params[:id].to_s.upcase)
        if country.nil?
          return render json: { success: false, message: 'Country not found' }, status: :not_found
        end

        cities = country.country_cities.active.by_priority
        render json: {
          success: true,
          country: format_country(country),
          data: cities.map { |city| format_city(city) }
        }, status: :ok
      end

      private

      def format_country(country)
        {
          id: country.id,
          name: country.name,
          iso_country_code: country.iso_country_code,
          iso_alpha3_code: country.iso_alpha3_code,
          calling_code: country.calling_code,
          default_timezone: country.default_timezone,
          whatsapp_consumer_status: country.whatsapp_consumer_status,
          whatsapp_business_status: country.whatsapp_business_status,
          whatsapp_api_eligibility: country.whatsapp_api_eligibility,
          default_cities_count: country.country_cities.active.default_pool.count
        }
      end

      def format_city(city)
        {
          id: city.id,
          name: city.name,
          state_or_region: city.state_or_region,
          administrative_classification: city.administrative_classification,
          commercial_priority: city.commercial_priority,
          is_default_discovery_pool: city.is_default_discovery_pool,
          aliases: city.aliases
        }
      end
    end
  end
end

