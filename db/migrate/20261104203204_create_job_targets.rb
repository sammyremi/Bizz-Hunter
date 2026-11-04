# frozen_string_literal: true

class CreateJobTargets < ActiveRecord::Migration[8.1]
  def change
    create_table :job_targets, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :job, type: :uuid, null: false, foreign_key: { to_table: :jobs, on_delete: :cascade }
      t.references :country, type: :uuid, null: false, foreign_key: { to_table: :countries, on_delete: :restrict }
      t.references :country_city, type: :uuid, foreign_key: { to_table: :country_cities, on_delete: :restrict }

      t.string :custom_city_name, limit: 100
      t.string :custom_region_name, limit: 100
      t.string :category, null: false, limit: 100
      t.boolean :is_active, null: false, default: true
      t.integer :search_count, null: false, default: 0
      t.integer :total_discovered_count, null: false, default: 0
      t.timestamptz :last_searched_at
      t.integer :rotation_priority, null: false, default: 100

      t.timestamps
    end

    add_index :job_targets,
              "job_id, country_id, country_city_id, lower(category)",
              unique: true,
              where: "country_city_id IS NOT NULL",
              name: "idx_job_targets_catalog_unique"

    add_index :job_targets,
              "job_id, country_id, lower(custom_city_name), lower(category)",
              unique: true,
              where: "country_city_id IS NULL",
              name: "idx_job_targets_custom_unique"

    add_index :job_targets,
              [:job_id, :is_active, :last_searched_at],
              name: "idx_job_targets_rotation"

    add_check_constraint :job_targets,
                         "(country_city_id IS NOT NULL) OR (custom_city_name IS NOT NULL)",
                         name: "chk_job_targets_city_source"
  end
end

