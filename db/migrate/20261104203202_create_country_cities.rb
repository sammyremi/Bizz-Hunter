# frozen_string_literal: true

class CreateCountryCities < ActiveRecord::Migration[8.1]
  def change
    create_table :country_cities, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :country, type: :uuid, null: false, foreign_key: { to_table: :countries, on_delete: :restrict }
      t.string :name, null: false, limit: 100
      t.string :state_or_region, limit: 100
      t.string :administrative_classification, null: false, default: "municipality", limit: 50
      t.integer :commercial_priority, null: false, default: 100
      t.boolean :is_default_discovery_pool, null: false, default: true
      t.boolean :is_active, null: false, default: true
      t.jsonb :aliases, null: false, default: []
      t.string :data_source, null: false, default: "geographical_gazetteer_2026", limit: 100
      t.timestamptz :last_verified_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :country_cities,
              "country_id, lower(name), COALESCE(lower(state_or_region), '')",
              unique: true,
              name: "idx_country_cities_country_and_canonical_name"
    add_index :country_cities,
              [:country_id, :is_default_discovery_pool, :is_active],
              name: "idx_country_cities_pool_lookup"
    add_index :country_cities, :commercial_priority

    add_check_constraint :country_cities, "commercial_priority > 0", name: "chk_country_cities_priority"
    add_check_constraint :country_cities,
                         "administrative_classification IN ('metropolis', 'municipality', 'urban_district', 'settlement')",
                         name: "chk_country_cities_classification"
  end
end

