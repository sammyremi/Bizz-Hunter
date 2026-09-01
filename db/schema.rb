# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_01_140002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  create_table "prospects", force: :cascade do |t|
    t.string "address"
    t.string "business_name", null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "follow_up_at"
    t.string "google_maps_url"
    t.string "google_place_id", null: false
    t.string "international_phone_number"
    t.float "latitude"
    t.float "longitude"
    t.text "notes"
    t.string "phone_number"
    t.float "rating"
    t.integer "review_count"
    t.string "status", default: "NEW", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.string "website"
    t.index ["user_id", "google_place_id"], name: "index_prospects_on_user_id_and_google_place_id", unique: true
    t.index ["user_id", "status"], name: "index_prospects_on_user_id_and_status"
    t.index ["user_id"], name: "index_prospects_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "prospects", "users", on_delete: :cascade
end
