# frozen_string_literal: true

# app/controllers/api/v1/jobs_controller.rb
module Api
  module V1
    class JobsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_job, only: %i[show update pause resume archive targets]

      # GET /api/v1/jobs
      def index
        scope = current_user.jobs
        scope = params[:status] == 'archived' ? scope.archived : scope.unarchived
        jobs = scope.order(created_at: :desc)

        render json: {
          success: true,
          data: JobSerializer.render(jobs)
        }, status: :ok
      end

      # GET /api/v1/jobs/:id
      def show
        render json: {
          success: true,
          data: JobSerializer.render(@job, include_targets: true)
        }, status: :ok
      end

      # POST /api/v1/jobs
      def create
        result = Jobs::Create.call(
          user: current_user,
          params: job_params,
          target_params: params[:target_generation]
        )

        if result[:success]
          render json: {
            success: true,
            message: result[:message],
            data: JobSerializer.render(result[:job], include_targets: true)
          }, status: :created
        else
          render json: {
            success: false,
            message: result[:message],
            errors: result[:errors]
          }, status: result[:status] || :unprocessable_entity
        end
      end

      # PATCH /api/v1/jobs/:id
      def update
        result = Jobs::Update.call(
          job: @job,
          params: job_params,
          target_params: params[:target_generation]
        )

        if result[:success]
          render json: {
            success: true,
            message: result[:message],
            data: JobSerializer.render(result[:job], include_targets: true)
          }, status: :ok
        else
          render json: {
            success: false,
            message: result[:message],
            errors: result[:errors]
          }, status: result[:status] || :unprocessable_entity
        end
      end

      # POST /api/v1/jobs/:id/pause
      def pause
        if @job.archived?
          return render json: { success: false, message: 'Cannot pause an archived Job' }, status: :unprocessable_entity
        end

        if @job.status == 'paused'
          return render json: { success: true, message: 'Job is already paused', data: JobSerializer.render(@job) }, status: :ok
        end

        @job.update!(status: 'paused')
        render json: {
          success: true,
          message: "Job '#{@job.name}' has been paused",
          data: JobSerializer.render(@job)
        }, status: :ok
      end

      # POST /api/v1/jobs/:id/resume
      def resume
        if @job.archived?
          return render json: { success: false, message: 'Cannot resume an archived Job' }, status: :unprocessable_entity
        end

        if @job.job_targets.active.none?
          return render json: { success: false, message: 'Cannot activate a Job with zero active targets' }, status: :unprocessable_entity
        end

        @job.update!(status: 'active')
        render json: {
          success: true,
          message: "Job '#{@job.name}' is now active",
          data: JobSerializer.render(@job)
        }, status: :ok
      end

      # POST /api/v1/jobs/:id/archive
      def archive
        if @job.archived?
          return render json: { success: true, message: 'Job is already archived', data: JobSerializer.render(@job) }, status: :ok
        end

        @job.archive!
        render json: {
          success: true,
          message: "Job '#{@job.name}' has been archived",
          data: JobSerializer.render(@job)
        }, status: :ok
      end

      # GET /api/v1/jobs/:id/targets
      def targets
        targets = @job.job_targets.order(Arel.sql('last_searched_at ASC NULLS FIRST, rotation_priority ASC'))
        render json: {
          success: true,
          data: JobTargetSerializer.render(targets)
        }, status: :ok
      end

      private

      def set_job
        @job = current_user.jobs.find_by(id: params[:id])
        return if @job.present?

        render json: {
          success: false,
          message: 'Job not found'
        }, status: :not_found
      end

      def job_params
        params.require(:job).permit(
          :name,
          :prospecting_profile_id,
          :outreach_mode,
          :website_targeting,
          :daily_discovery_target,
          :daily_outreach_target,
          :outreach_interval_seconds,
          :timezone,
          :discovery_schedule,
          :discovery_window_start,
          :discovery_window_end,
          :outreach_window_start,
          :outreach_window_end,
          :message_template,
          active_weekdays: []
        )
      end
    end
  end
end

