# frozen_string_literal: true

# app/services/jobs/generate_targets.rb
module Jobs
  class GenerateTargets < ApplicationService
    def initialize(job:, target_params:)
      @job = job
      raw_params = target_params.respond_to?(:to_unsafe_h) ? target_params.to_unsafe_h : target_params
      @target_params = (raw_params || {}).with_indifferent_access
    end

    def call
      country_identifiers = Array(@target_params[:countries]).compact_blank
      raw_categories      = Array(@target_params[:categories]).compact_blank.map { |c| c.to_s.strip.downcase }.uniq
      city_mode           = @target_params[:city_mode].presence || 'automatic' # 'automatic' or 'manual'
      manual_city_ids     = Array(@target_params[:city_ids]).compact_blank
      custom_cities       = Array(@target_params[:custom_cities])
      excluded_city_ids   = Array(@target_params[:excluded_city_ids]).compact_blank

      if country_identifiers.blank?
        return { success: false, message: 'At least one country must be selected' }
      end

      if raw_categories.blank?
        return { success: false, message: 'At least one business category must be selected' }
      end

      # Resolve active countries by UUID or ISO-2 code
      countries = Country.active.where('id::text IN (:ids) OR iso_country_code IN (:codes)',
                                       ids: country_identifiers, codes: country_identifiers.map(&:upcase))

      if countries.blank?
        return { success: false, message: 'None of the selected countries are currently active or supported' }
      end

      Job.transaction do
        kept_target_ids = []

        countries.each do |country|
          # Determine eligible cities for this country
          eligible_catalog_cities = []

          if city_mode == 'automatic'
            # Load up to 20 default pool cities for the country, minus any Job-specific exclusions
            pool = country.country_cities.active.default_pool
            pool = pool.where.not(id: excluded_city_ids) if excluded_city_ids.present?
            eligible_catalog_cities = pool.to_a
          else
            # Manual city mode: select specific catalog cities for this country
            if manual_city_ids.present?
              cities_scope = country.country_cities.active.where(id: manual_city_ids)
              cities_scope = cities_scope.where.not(id: excluded_city_ids) if excluded_city_ids.present?
              eligible_catalog_cities = cities_scope.to_a
            end
          end

          # Generate or synchronize catalog targets
          eligible_catalog_cities.each do |city|
            raw_categories.each do |cat|
              target = @job.job_targets.find_or_initialize_by(
                country: country,
                country_city: city,
                category: cat
              )

              # If new, assign priority and defaults; if existing, do not overwrite progress
              target.rotation_priority = city.commercial_priority if target.new_record?
              target.is_active = true
              target.save!
              kept_target_ids << target.id
            end
          end

          # Handle custom cities if in manual mode
          if city_mode == 'manual' && custom_cities.present?
            custom_cities.each do |custom_data|
              c_data = custom_data.is_a?(Hash) ? custom_data.with_indifferent_access : { name: custom_data.to_s }
              c_country_id = c_data[:country_id] || c_data[:country_code]

              # Match custom city to the current country if specified, or default to current country if only 1 country
              if c_country_id.present?
                next unless c_country_id == country.id || c_country_id.to_s.upcase == country.iso_country_code
              elsif countries.size > 1
                # Ambiguous without country reference
                next
              end

              custom_name = c_data[:name].to_s.strip
              custom_region = c_data[:region_name] || c_data[:state_or_region]
              next if custom_name.blank?

              raw_categories.each do |cat|
                target = @job.job_targets.find_or_initialize_by(
                  country: country,
                  country_city: nil,
                  custom_city_name: custom_name,
                  category: cat
                )

                target.custom_region_name = custom_region if target.new_record?
                target.is_active = true
                target.save!
                kept_target_ids << target.id
              end
            end
          end
        end

        # Safely deactivate (or prune unsearched) targets that are no longer part of configuration
        # If target has search history (search_count > 0), preserve it by setting is_active = false
        unselected_targets = @job.job_targets.where.not(id: kept_target_ids)
        unselected_targets.where('search_count > 0').update_all(is_active: false, updated_at: Time.current)
        unselected_targets.where(search_count: 0).destroy_all

        {
          success: true,
          message: "Synchronized targets for Job '#{@job.name}'",
          total_targets_count: @job.job_targets.count,
          active_targets_count: @job.job_targets.active.count
        }
      end
    rescue StandardError => e
      Rails.logger.error("[Jobs::GenerateTargets] Failed: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      { success: false, message: e.message }
    end
  end
end
