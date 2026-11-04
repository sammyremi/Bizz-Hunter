# frozen_string_literal: true

class CreateOutreachTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :outreach_tasks, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :job, type: :uuid, null: false, foreign_key: { to_table: :jobs, on_delete: :cascade }
      t.references :job_prospect, type: :uuid, null: false, foreign_key: { to_table: :job_prospects, on_delete: :cascade }
      t.references :extension_device, type: :uuid, foreign_key: { to_table: :extension_devices, on_delete: :nullify }

      t.string :status, null: false, default: "queued", limit: 32
      t.text :prepared_message, null: false
      t.string :destination_phone, null: false, limit: 32
      t.text :whatsapp_url, null: false
      t.timestamptz :scheduled_for, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamptz :dispatched_at
      t.timestamptz :sending_at
      t.timestamptz :completed_at
      t.integer :attempt_count, null: false, default: 0
      t.string :error_code, limit: 64
      t.text :error_details
      t.string :idempotency_key, null: false, limit: 128
      t.string :dispatch_token_digest, limit: 64
      t.timestamptz :dispatch_token_expires_at

      t.timestamps
    end

    add_index :outreach_tasks, :idempotency_key, unique: true
    add_index :outreach_tasks,
              [:job_id, :status, :scheduled_for],
              where: "status IN ('queued', 'retrying')",
              name: "idx_outreach_tasks_poll"
    add_index :outreach_tasks,
              :dispatch_token_digest,
              where: "dispatch_token_digest IS NOT NULL",
              name: "idx_outreach_tasks_dispatch_token"

    add_check_constraint :outreach_tasks, "attempt_count >= 0", name: "chk_outreach_tasks_attempt_count"
    add_check_constraint :outreach_tasks,
                         "status IN ('pending_review', 'approved', 'queued', 'dispatched', 'sending', 'sent', 'failed', 'uncertain', 'skipped', 'cancelled', 'retrying')",
                         name: "chk_outreach_tasks_status"
  end
end

