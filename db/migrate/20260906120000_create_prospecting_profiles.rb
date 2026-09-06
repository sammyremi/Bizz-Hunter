# db/migrate/20260906120000_create_prospecting_profiles.rb

# frozen_string_literal: true

class CreateProspectingProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :prospecting_profiles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id, null: false
      t.string :name, null: false
      t.string :service, null: false
      t.text :service_description, null: false
      t.jsonb :target_businesses, default: []
      t.jsonb :opportunity_signals, default: []
      t.jsonb :contact_signals, default: []
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :prospecting_profiles, :user_id
    add_index :prospecting_profiles, [:user_id, :is_default]
    add_foreign_key :prospecting_profiles, :users, on_delete: :cascade
  end
end
