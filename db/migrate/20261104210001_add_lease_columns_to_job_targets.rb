# frozen_string_literal: true

class AddLeaseColumnsToJobTargets < ActiveRecord::Migration[8.1]
  def change
    add_column :job_targets, :lease_token, :string, limit: 64
    add_column :job_targets, :leased_at, :timestamptz
    add_column :job_targets, :lease_expires_at, :timestamptz

    add_index :job_targets,
              [:job_id, :is_active, :lease_expires_at, :last_searched_at],
              name: "idx_job_targets_lease_rotation"
  end
end

