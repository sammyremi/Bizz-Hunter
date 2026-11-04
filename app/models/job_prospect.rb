# frozen_string_literal: true

class JobProspect < ApplicationRecord
  belongs_to :job
  belongs_to :prospect
  belongs_to :search_result, optional: true
  has_many :outreach_tasks, dependent: :restrict_with_error

  QUALIFICATION_STATUSES = %w[qualified disqualified pending_criteria].freeze
  REVIEW_STATUSES = %w[pending approved rejected auto_approved].freeze
  WEBSITE_STATUSES = %w[no_website_found website_found weak_or_outdated unknown needs_verification].freeze

  validates :qualification_status, inclusion: { in: QUALIFICATION_STATUSES }
  validates :review_status, inclusion: { in: REVIEW_STATUSES }
  validates :website_status, inclusion: { in: WEBSITE_STATUSES }
  validates :prospect_id, uniqueness: { scope: :job_id, message: 'has already been associated with this Job' }
  validate :validate_prospect_user_ownership
  validate :validate_search_result_user_ownership

  scope :qualified, -> { where(qualification_status: 'qualified') }
  scope :approved, -> { where(review_status: %w[approved auto_approved]) }
  scope :pending_review, -> { where(review_status: 'pending') }

  def approved?
    review_status.in?(%w[approved auto_approved])
  end

  private

  def validate_prospect_user_ownership
    return if prospect.nil? || job.nil?

    if prospect.user_id != job.user_id
      errors.add(:prospect, 'must belong to the same user as the Job')
    end
  end

  def validate_search_result_user_ownership
    return if search_result.nil? || job.nil?

    if search_result.user_id.present? && search_result.user_id != job.user_id
      errors.add(:search_result, 'must belong to the same user as the Job')
    end
  end
end

