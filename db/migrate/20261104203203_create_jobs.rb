# frozen_string_literal: true

class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, type: :uuid, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :prospecting_profile, type: :uuid, foreign_key: { to_table: :prospecting_profiles, on_delete: :nullify }

      t.string :name, null: false, limit: 255
      t.string :status, null: false, default: "draft", limit: 32
      t.string :outreach_mode, null: false, default: "manual_review", limit: 32
      t.string :website_targeting, null: false, default: "both", limit: 32
      t.integer :daily_discovery_target, null: false, default: 50
      t.integer :daily_outreach_target, null: false, default: 0
      t.integer :outreach_interval_seconds, null: false, default: 120
      t.string :timezone, null: false, default: "UTC", limit: 64
      t.string :discovery_schedule, null: false, default: "0 8 * * *", limit: 64
      t.time :discovery_window_start, null: false, default: "08:00:00"
      t.time :discovery_window_end, null: false, default: "20:00:00"
      t.time :outreach_window_start, null: false, default: "09:00:00"
      t.time :outreach_window_end, null: false, default: "17:00:00"
      t.integer :active_weekdays, array: true, null: false, default: [1, 2, 3, 4, 5]
      t.text :message_template, null: false
      t.timestamptz :last_discovery_at
      t.timestamptz :next_discovery_at
      t.timestamptz :last_outreach_at
      t.timestamptz :archived_at

      t.timestamps
    end

    add_index :jobs, :status
    add_index :jobs, [:status, :next_discovery_at], where: "status = 'active'", name: "idx_jobs_active_discovery_poll"

    add_check_constraint :jobs, "daily_discovery_target > 0 AND daily_discovery_target <= 500", name: "chk_jobs_daily_discovery"
    add_check_constraint :jobs, "daily_outreach_target >= 0 AND daily_outreach_target <= 100", name: "chk_jobs_daily_outreach"
    add_check_constraint :jobs, "outreach_interval_seconds >= 60", name: "chk_jobs_outreach_interval"
    add_check_constraint :jobs, "status IN ('draft', 'active', 'paused', 'completed', 'archived')", name: "chk_jobs_status"
    add_check_constraint :jobs, "outreach_mode IN ('manual_review', 'automatic')", name: "chk_jobs_outreach_mode"
    add_check_constraint :jobs, "website_targeting IN ('no_website', 'weak_or_outdated', 'both')", name: "chk_jobs_website_targeting"
  end
end

