# frozen_string_literal: true

class CreateCountries < ActiveRecord::Migration[8.1]
  def change
    create_table :countries, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :iso_country_code, null: false, limit: 2
      t.string :iso_alpha3_code, null: false, limit: 3
      t.string :name, null: false, limit: 100
      t.string :calling_code, null: false, limit: 8
      t.string :default_timezone, null: false, default: "UTC", limit: 64
      t.string :whatsapp_consumer_status, null: false, default: "widespread", limit: 32
      t.string :whatsapp_business_status, null: false, default: "available", limit: 32
      t.string :whatsapp_api_eligibility, null: false, default: "eligible", limit: 32
      t.boolean :is_active, null: false, default: true
      t.string :data_source, null: false, default: "system_seed", limit: 100
      t.timestamptz :last_verified_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :countries, :iso_country_code, unique: true
    add_index :countries, :iso_alpha3_code, unique: true
    add_index :countries, :is_active, where: "is_active = true"

    add_check_constraint :countries, "iso_country_code ~ '^[A-Z]{2}$'", name: "chk_countries_iso_alpha2"
    add_check_constraint :countries, "calling_code ~ '^[0-9]{1,6}$'", name: "chk_countries_calling_code"
    add_check_constraint :countries,
                         "whatsapp_consumer_status IN ('widespread', 'moderate', 'limited', 'unsupported')",
                         name: "chk_countries_whatsapp_consumer"
    add_check_constraint :countries,
                         "whatsapp_business_status IN ('available', 'restricted', 'unknown')",
                         name: "chk_countries_whatsapp_business"
    add_check_constraint :countries,
                         "whatsapp_api_eligibility IN ('eligible', 'restricted', 'prohibited')",
                         name: "chk_countries_whatsapp_api"
  end
end

