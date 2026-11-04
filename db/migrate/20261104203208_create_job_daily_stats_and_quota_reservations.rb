# frozen_string_literal: true

class CreateJobDailyStatsAndQuotaReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :job_daily_stats, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :job, type: :uuid, null: false, foreign_key: { to_table: :jobs, on_delete: :cascade }
      t.date :stat_date, null: false

      t.integer :businesses_found, null: false, default: 0
      t.integer :unique_new_businesses, null: false, default: 0
      t.integer :duplicate_businesses, null: false, default: 0
      t.integer :prospects_qualified, null: false, default: 0
      t.integer :messages_prepared, null: false, default: 0
      t.integer :outreach_dispatched, null: false, default: 0
      t.integer :outreach_confirmed, null: false, default: 0
      t.integer :outreach_failed, null: false, default: 0
      t.integer :outreach_uncertain, null: false, default: 0
      t.integer :prospects_skipped, null: false, default: 0

      t.timestamps
    end

    add_index :job_daily_stats, [:job_id, :stat_date], unique: true, name: "idx_job_daily_stats_job_and_date"

    create_table :quota_reservations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :job, type: :uuid, null: false, foreign_key: { to_table: :jobs, on_delete: :cascade }
      t.string :quota_type, null: false, limit: 32
      t.date :stat_date, null: false
      t.integer :amount, null: false, default: 1
      t.string :status, null: false, default: "reserved", limit: 32
      t.string :reservation_key, null: false, limit: 128
      t.timestamptz :expires_at, null: false

      t.timestamps
    end

    add_index :quota_reservations, :reservation_key, unique: true
    add_index :quota_reservations,
              [:job_id, :quota_type, :stat_date, :status],
              name: "idx_quota_reservations_active"

    add_check_constraint :quota_reservations,
                         "quota_type IN ('discovery', 'outreach')",
                         name: "chk_quota_reservations_type"
    add_check_constraint :quota_reservations,
                         "status IN ('reserved', 'consumed', 'released', 'expired')",
                         name: "chk_quota_reservations_status"
    add_check_constraint :quota_reservations, "amount > 0", name: "chk_quota_reservations_amount"
  end
end

