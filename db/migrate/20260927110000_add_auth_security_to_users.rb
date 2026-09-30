# db/migrate/20260927110000_add_auth_security_to_users.rb
# frozen_string_literal: true

class AddAuthSecurityToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :verified_at, :datetime
    add_column :users, :verification_token_digest, :string
    add_column :users, :verification_sent_at, :datetime
    add_column :users, :reset_password_token_digest, :string
    add_column :users, :reset_password_sent_at, :datetime

    add_index :users, :verification_token_digest
    add_index :users, :reset_password_token_digest

    # Backfill pre-existing users so existing accounts remain verified
    User.reset_column_information
    User.update_all(verified_at: Time.current)
  end

  def down
    remove_index :users, :verification_token_digest, if_exists: true
    remove_index :users, :reset_password_token_digest, if_exists: true

    remove_column :users, :reset_password_sent_at, :datetime
    remove_column :users, :reset_password_token_digest, :string
    remove_column :users, :verification_sent_at, :datetime
    remove_column :users, :verification_token_digest, :string
    remove_column :users, :verified_at, :datetime
  end
end
