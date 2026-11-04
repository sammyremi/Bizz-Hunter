# frozen_string_literal: true

class AddSafetyConstraintsToJobs < ActiveRecord::Migration[8.1]
  def up
    # 1. Geographic consistency: mutually exclusive city source
    # Must have EITHER (country_city_id IS NOT NULL AND custom_city_name IS NULL)
    # OR (country_city_id IS NULL AND custom_city_name IS NOT NULL)
    remove_check_constraint :job_targets, name: "chk_job_targets_city_source" if check_constraint_exists?(:job_targets, name: "chk_job_targets_city_source")

    add_check_constraint :job_targets,
                         "((country_city_id IS NOT NULL AND custom_city_name IS NULL) OR (country_city_id IS NULL AND custom_city_name IS NOT NULL))",
                         name: "chk_job_targets_mutually_exclusive_city"

    # 2. Prevent silent cascade deletion of sent, failed, or uncertain outreach records:
    # Change FK on outreach_tasks.job_id from CASCADE to RESTRICT
    remove_foreign_key :outreach_tasks, :jobs if foreign_key_exists?(:outreach_tasks, :jobs)
    add_foreign_key :outreach_tasks, :jobs, on_delete: :restrict

    # Change FK on outreach_tasks.job_prospect_id from CASCADE to RESTRICT
    remove_foreign_key :outreach_tasks, :job_prospects if foreign_key_exists?(:outreach_tasks, :job_prospects)
    add_foreign_key :outreach_tasks, :job_prospects, on_delete: :restrict
  end

  def down
    remove_foreign_key :outreach_tasks, :job_prospects if foreign_key_exists?(:outreach_tasks, :job_prospects)
    add_foreign_key :outreach_tasks, :job_prospects, on_delete: :cascade

    remove_foreign_key :outreach_tasks, :jobs if foreign_key_exists?(:outreach_tasks, :jobs)
    add_foreign_key :outreach_tasks, :jobs, on_delete: :cascade

    remove_check_constraint :job_targets, name: "chk_job_targets_mutually_exclusive_city" if check_constraint_exists?(:job_targets, name: "chk_job_targets_mutually_exclusive_city")

    add_check_constraint :job_targets,
                         "(country_city_id IS NOT NULL) OR (custom_city_name IS NOT NULL)",
                         name: "chk_job_targets_city_source"
  end
end

