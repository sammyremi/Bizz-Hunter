# db/migrate/20260915000000_add_ai_preferences_to_users.rb

class AddAiPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ai_tone, :string, default: 'Professional', null: false
    add_column :users, :ai_length, :string, default: 'Short', null: false
  end
end
