# frozen_string_literal: true

class CreateJobProspects < ActiveRecord::Migration[8.1]
  def change
    create_table :job_prospects, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :job, type: :uuid, null: false, foreign_key: { to_table: :jobs, on_delete: :cascade }
      t.references :prospect, type: :bigint, null: false, foreign_key: { to_table: :prospects, on_delete: :cascade }
      t.references :search_result, type: :uuid, foreign_key: { to_table: :search_results, on_delete: :nullify }

      t.string :qualification_status, null: false, default: "qualified", limit: 32
      t.text :qualification_reason
      t.integer :opportunity_score
      t.string :website_status, null: false, default: "unknown", limit: 32
      t.string :review_status, null: false, default: "pending", limit: 32
      t.string :skip_reason, limit: 255
      t.timestamptz :discovered_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :job_prospects, [:job_id, :prospect_id], unique: true, name: "idx_job_prospects_job_and_prospect"
    add_index :job_prospects, [:job_id, :review_status, :qualification_status], name: "idx_job_prospects_review_lookup"

    add_check_constraint :job_prospects,
                         "qualification_status IN ('qualified', 'disqualified', 'pending_criteria')",
                         name: "chk_job_prospects_qualification"
    add_check_constraint :job_prospects,
                         "review_status IN ('pending', 'approved', 'rejected', 'auto_approved')",
                         name: "chk_job_prospects_review"
    add_check_constraint :job_prospects,
                         "website_status IN ('no_website_found', 'website_found', 'weak_or_outdated', 'unknown', 'needs_verification')",
                         name: "chk_job_prospects_website_status"
  end
end

