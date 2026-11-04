# frozen_string_literal: true

# app/services/jobs/update.rb
module Jobs
  class Update < ApplicationService
    def initialize(job:, params:, target_params: nil)
      @job = job
      @params = (params || {}).to_h.symbolize_keys
      @target_params = target_params
    end

    def call
      if @job.archived?
        return { success: false, message: 'Cannot modify an archived Job', status: :unprocessable_entity }
      end

      # Disallow changing status arbitrarily via generic update (must use state action endpoints)
      filtered_params = @params.except(:status, :user_id, :archived_at)

      result = nil
      Job.transaction do
        @job.assign_attributes(filtered_params)

        if @job.save
          if @target_params.present?
            target_result = Jobs::GenerateTargets.call(job: @job, target_params: @target_params)
            unless target_result[:success]
              result = { success: false, message: target_result[:message], status: :unprocessable_entity }
              raise ActiveRecord::Rollback
            end
          end

          result = { success: true, job: @job, message: 'Job updated successfully', status: :ok }
        else
          result = {
            success: false,
            message: @job.errors.full_messages.to_sentence,
            errors: @job.errors.to_hash,
            status: :unprocessable_entity
          }
        end
      end

      result || { success: false, message: 'Job update failed', status: :unprocessable_entity }
    rescue StandardError => e
      { success: false, message: e.message, status: :unprocessable_entity }
    end
  end
end
