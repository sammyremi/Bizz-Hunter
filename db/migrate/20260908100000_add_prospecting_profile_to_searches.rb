# db/migrate/20260908100000_add_prospecting_profile_to_searches.rb

# frozen_string_literal: true

class AddProspectingProfileToSearches < ActiveRecord::Migration[8.1]
  def change
    add_column :searches, :prospecting_profile_id, :uuid, null: true, default: nil

    add_index :searches, :prospecting_profile_id, name: "index_searches_on_prospecting_profile_id"

    add_foreign_key :searches, :prospecting_profiles,
                    column: :prospecting_profile_id,
                    on_delete: :nullify
  end
end
