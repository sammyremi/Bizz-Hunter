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

ActiveRecord::Schema[8.1].define(version: 2026_09_05_150000) do
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

  create_table "search_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address"
    t.string "business_type"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "google_maps_url"
    t.string "google_place_id", null: false
    t.float "latitude"
    t.float "longitude"
    t.string "name", null: false
    t.string "national_phone"
    t.jsonb "opportunity_factors", default: []
    t.string "opportunity_level", default: "LOW"
    t.integer "opportunity_score", default: 0
    t.string "opportunity_tier", default: "low"
    t.string "phone"
    t.float "rating"
    t.integer "review_count", default: 0
    t.uuid "search_id", null: false
    t.string "state"
    t.jsonb "types", default: []
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.string "website"
    t.index ["google_place_id"], name: "index_search_results_on_google_place_id"
    t.index ["opportunity_tier"], name: "index_search_results_on_opportunity_tier"
    t.index ["search_id"], name: "index_search_results_on_search_id"
    t.index ["user_id", "google_place_id"], name: "index_search_results_on_user_id_and_google_place_id"
    t.index ["user_id"], name: "index_search_results_on_user_id"
  end

  create_table "searches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "area"
    t.string "business_type"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "location_name"
    t.float "min_rating"
    t.string "phone_filter"
    t.string "query"
    t.integer "results_count", default: 0, null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.string "website_filter"
    t.index ["created_at"], name: "index_searches_on_created_at"
    t.index ["user_id"], name: "index_searches_on_user_id"
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
  add_foreign_key "search_results", "searches", on_delete: :cascade
  add_foreign_key "search_results", "users", on_delete: :cascade
  add_foreign_key "searches", "users", on_delete: :cascade
end
