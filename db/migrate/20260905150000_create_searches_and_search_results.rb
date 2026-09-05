# db/migrate/20260905150000_create_searches_and_search_results.rb

# frozen_string_literal: true

class CreateSearchesAndSearchResults < ActiveRecord::Migration[8.1]
  def change
    create_table :searches, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :user_id
      t.string :query
      t.string :business_type
      t.string :location_name
      t.string :country
      t.string :state
      t.string :city
      t.string :area
      t.float :min_rating
      t.string :website_filter
      t.string :phone_filter
      t.integer :results_count, default: 0, null: false

      t.timestamps
    end

    add_index :searches, :user_id
    add_index :searches, :created_at
    add_foreign_key :searches, :users, column: :user_id, on_delete: :cascade

    create_table :search_results, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :search_id, null: false
      t.uuid :user_id
      t.string :google_place_id, null: false
      t.string :name, null: false
      t.string :business_type
      t.jsonb :types, default: []
      t.string :address
      t.string :city
      t.string :state
      t.string :country
      t.float :latitude
      t.float :longitude
      t.string :phone
      t.string :national_phone
      t.string :website
      t.string :google_maps_url
      t.float :rating
      t.integer :review_count, default: 0
      t.integer :opportunity_score, default: 0
      t.string :opportunity_tier, default: "low"
      t.string :opportunity_level, default: "LOW"
      t.jsonb :opportunity_factors, default: []

      t.timestamps
    end

    add_index :search_results, :search_id
    add_index :search_results, :user_id
    add_index :search_results, :google_place_id
    add_index :search_results, :opportunity_tier
    add_index :search_results, [:user_id, :google_place_id]

    add_foreign_key :search_results, :searches, column: :search_id, on_delete: :cascade
    add_foreign_key :search_results, :users, column: :user_id, on_delete: :cascade
  end
end
