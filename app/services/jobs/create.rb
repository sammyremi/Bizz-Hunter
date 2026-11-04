# frozen_string_literal: true

# app/services/jobs/create.rb
module Jobs
  class Create < ApplicationService
    def initialize(user:, params:, target_params: nil)
      @user = user
      @params = (params || {}).to_h.symbolize_keys
      @target_params = target_params
    end

    def call
      return { success: false, message: 'User is required', status: :unauthorized } if @user.blank?

      job = @user.jobs.build(@params)

      # Ensure outreach mode safety
      job.outreach_mode = 'manual_review' if job.outreach_mode.blank?

      result = nil
      Job.transaction do
        if job.save
          if @target_params.present?
            target_result = Jobs::GenerateTargets.call(job: job, target_params: @target_params)
            unless target_result[:success]
              result = { success: false, message: target_result[:message], status: :unprocessable_entity }
              raise ActiveRecord::Rollback
            end
          end

          result = { success: true, job: job, message: 'Job created successfully', status: :created }
        else
          result = {
            success: false,
            message: job.errors.full_messages.to_sentence,
            errors: job.errors.to_hash,
            status: :unprocessable_entity
          }
        end
      end

      result || { success: false, message: 'Job creation failed', status: :unprocessable_entity }
    rescue StandardError => e
      { success: false, message: e.message, status: :unprocessable_entity }
    end
  end
end
