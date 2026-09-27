# db/migrate/20260925000000_add_google_oauth_to_users.rb

class AddGoogleOauthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :avatar_url, :string

    # Relax the NOT NULL constraint on password_digest so Google-only users
    # can exist without a password. Existing rows already have a value so this
    # is safe and non-destructive.
    change_column_null :users, :password_digest, true

    # Composite index so lookups by provider+uid are fast and unique
    add_index :users, [ :provider, :uid ], unique: true, name: 'index_users_on_provider_and_uid'
  end
end
