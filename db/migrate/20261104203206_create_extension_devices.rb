# frozen_string_literal: true

class CreateExtensionDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :extension_devices, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, type: :uuid, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.uuid :device_uuid, null: false, default: -> { "gen_random_uuid()" }
      t.string :client_name, limit: 100
      t.string :api_key_digest, null: false, limit: 64
      t.string :extension_version, limit: 32
      t.string :browser_name, null: false, default: "Brave", limit: 64
      t.string :os_name, limit: 64
      t.string :status, null: false, default: "offline", limit: 32
      t.timestamptz :last_heartbeat_at
      t.timestamptz :registered_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamptz :revoked_at

      t.timestamps
    end

    add_index :extension_devices, :device_uuid, unique: true
    add_index :extension_devices, :api_key_digest, unique: true
    add_index :extension_devices, [:user_id, :status], name: "idx_extension_devices_user_status"

    add_check_constraint :extension_devices,
                         "status IN ('online', 'busy', 'paused', 'offline', 'revoked')",
                         name: "chk_extension_devices_status"
  end
end

