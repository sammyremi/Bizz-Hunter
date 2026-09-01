class CreateProspects < ActiveRecord::Migration[8.1]
  def change
    create_table :prospects do |t|
      t.references :user, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :google_place_id, null: false
      t.string :business_name, null: false
      t.string :category
      t.string :address
      t.float :latitude
      t.float :longitude
      t.float :rating
      t.integer :review_count
      t.string :phone_number
      t.string :international_phone_number
      t.string :website
      t.string :google_maps_url
      t.string :status, null: false, default: 'NEW'
      t.text :notes
      t.datetime :follow_up_at

      t.timestamps
    end

    add_index :prospects, [:user_id, :google_place_id], unique: true
    add_index :prospects, [:user_id, :status]
  end
end
