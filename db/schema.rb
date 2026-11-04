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

ActiveRecord::Schema[8.1].define(version: 2026_11_04_210001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  create_table "countries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "calling_code", limit: 8, null: false
    t.datetime "created_at", null: false
    t.string "data_source", limit: 100, default: "system_seed", null: false
    t.string "default_timezone", limit: 64, default: "UTC", null: false
    t.boolean "is_active", default: true, null: false
    t.string "iso_alpha3_code", limit: 3, null: false
    t.string "iso_country_code", limit: 2, null: false
    t.timestamptz "last_verified_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "name", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.string "whatsapp_api_eligibility", limit: 32, default: "eligible", null: false
    t.string "whatsapp_business_status", limit: 32, default: "available", null: false
    t.string "whatsapp_consumer_status", limit: 32, default: "widespread", null: false
    t.index ["is_active"], name: "index_countries_on_is_active", where: "(is_active = true)"
    t.index ["iso_alpha3_code"], name: "index_countries_on_iso_alpha3_code", unique: true
    t.index ["iso_country_code"], name: "index_countries_on_iso_country_code", unique: true
    t.check_constraint "calling_code::text ~ '^[0-9]{1,6}$'::text", name: "chk_countries_calling_code"
    t.check_constraint "iso_country_code::text ~ '^[A-Z]{2}$'::text", name: "chk_countries_iso_alpha2"
    t.check_constraint "whatsapp_api_eligibility::text = ANY (ARRAY['eligible'::character varying, 'restricted'::character varying, 'prohibited'::character varying]::text[])", name: "chk_countries_whatsapp_api"
    t.check_constraint "whatsapp_business_status::text = ANY (ARRAY['available'::character varying, 'restricted'::character varying, 'unknown'::character varying]::text[])", name: "chk_countries_whatsapp_business"
    t.check_constraint "whatsapp_consumer_status::text = ANY (ARRAY['widespread'::character varying, 'moderate'::character varying, 'limited'::character varying, 'unsupported'::character varying]::text[])", name: "chk_countries_whatsapp_consumer"
  end

  create_table "country_cities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "administrative_classification", limit: 50, default: "municipality", null: false
    t.jsonb "aliases", default: [], null: false
    t.integer "commercial_priority", default: 100, null: false
    t.uuid "country_id", null: false
    t.datetime "created_at", null: false
    t.string "data_source", limit: 100, default: "geographical_gazetteer_2026", null: false
    t.boolean "is_active", default: true, null: false
    t.boolean "is_default_discovery_pool", default: true, null: false
    t.timestamptz "last_verified_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "name", limit: 100, null: false
    t.string "state_or_region", limit: 100
    t.datetime "updated_at", null: false
    t.index "country_id, lower((name)::text), COALESCE(lower((state_or_region)::text), ''::text)", name: "idx_country_cities_country_and_canonical_name", unique: true
    t.index ["commercial_priority"], name: "index_country_cities_on_commercial_priority"
    t.index ["country_id", "is_default_discovery_pool", "is_active"], name: "idx_country_cities_pool_lookup"
    t.index ["country_id"], name: "index_country_cities_on_country_id"
    t.check_constraint "administrative_classification::text = ANY (ARRAY['metropolis'::character varying, 'municipality'::character varying, 'urban_district'::character varying, 'settlement'::character varying]::text[])", name: "chk_country_cities_classification"
    t.check_constraint "commercial_priority > 0", name: "chk_country_cities_priority"
  end

  create_table "extension_devices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "api_key_digest", limit: 64, null: false
    t.string "browser_name", limit: 64, default: "Brave", null: false
    t.string "client_name", limit: 100
    t.datetime "created_at", null: false
    t.uuid "device_uuid", default: -> { "gen_random_uuid()" }, null: false
    t.string "extension_version", limit: 32
    t.timestamptz "last_heartbeat_at"
    t.string "os_name", limit: 64
    t.timestamptz "registered_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamptz "revoked_at"
    t.string "status", limit: 32, default: "offline", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["api_key_digest"], name: "index_extension_devices_on_api_key_digest", unique: true
    t.index ["device_uuid"], name: "index_extension_devices_on_device_uuid", unique: true
    t.index ["user_id", "status"], name: "idx_extension_devices_user_status"
    t.index ["user_id"], name: "index_extension_devices_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['online'::character varying, 'busy'::character varying, 'paused'::character varying, 'offline'::character varying, 'revoked'::character varying]::text[])", name: "chk_extension_devices_status"
  end

  create_table "job_daily_stats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "businesses_found", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "duplicate_businesses", default: 0, null: false
    t.uuid "job_id", null: false
    t.integer "messages_prepared", default: 0, null: false
    t.integer "outreach_confirmed", default: 0, null: false
    t.integer "outreach_dispatched", default: 0, null: false
    t.integer "outreach_failed", default: 0, null: false
    t.integer "outreach_uncertain", default: 0, null: false
    t.integer "prospects_qualified", default: 0, null: false
    t.integer "prospects_skipped", default: 0, null: false
    t.date "stat_date", null: false
    t.integer "unique_new_businesses", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "stat_date"], name: "idx_job_daily_stats_job_and_date", unique: true
    t.index ["job_id"], name: "index_job_daily_stats_on_job_id"
  end

  create_table "job_prospects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.timestamptz "discovered_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "job_id", null: false
    t.integer "opportunity_score"
    t.bigint "prospect_id", null: false
    t.text "qualification_reason"
    t.string "qualification_status", limit: 32, default: "qualified", null: false
    t.string "review_status", limit: 32, default: "pending", null: false
    t.uuid "search_result_id"
    t.string "skip_reason", limit: 255
    t.datetime "updated_at", null: false
    t.string "website_status", limit: 32, default: "unknown", null: false
    t.index ["job_id", "prospect_id"], name: "idx_job_prospects_job_and_prospect", unique: true
    t.index ["job_id", "review_status", "qualification_status"], name: "idx_job_prospects_review_lookup"
    t.index ["job_id"], name: "index_job_prospects_on_job_id"
    t.index ["prospect_id"], name: "index_job_prospects_on_prospect_id"
    t.index ["search_result_id"], name: "index_job_prospects_on_search_result_id"
    t.check_constraint "qualification_status::text = ANY (ARRAY['qualified'::character varying, 'disqualified'::character varying, 'pending_criteria'::character varying]::text[])", name: "chk_job_prospects_qualification"
    t.check_constraint "review_status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'auto_approved'::character varying]::text[])", name: "chk_job_prospects_review"
    t.check_constraint "website_status::text = ANY (ARRAY['no_website_found'::character varying, 'website_found'::character varying, 'weak_or_outdated'::character varying, 'unknown'::character varying, 'needs_verification'::character varying]::text[])", name: "chk_job_prospects_website_status"
  end

  create_table "job_targets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "category", limit: 100, null: false
    t.uuid "country_city_id"
    t.uuid "country_id", null: false
    t.datetime "created_at", null: false
    t.string "custom_city_name", limit: 100
    t.string "custom_region_name", limit: 100
    t.boolean "is_active", default: true, null: false
    t.uuid "job_id", null: false
    t.timestamptz "last_searched_at"
    t.timestamptz "lease_expires_at"
    t.string "lease_token", limit: 64
    t.timestamptz "leased_at"
    t.integer "rotation_priority", default: 100, null: false
    t.integer "search_count", default: 0, null: false
    t.integer "total_discovered_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index "job_id, country_id, country_city_id, lower((category)::text)", name: "idx_job_targets_catalog_unique", unique: true, where: "(country_city_id IS NOT NULL)"
    t.index "job_id, country_id, lower((custom_city_name)::text), lower((category)::text)", name: "idx_job_targets_custom_unique", unique: true, where: "(country_city_id IS NULL)"
    t.index ["country_city_id"], name: "index_job_targets_on_country_city_id"
    t.index ["country_id"], name: "index_job_targets_on_country_id"
    t.index ["job_id", "is_active", "last_searched_at"], name: "idx_job_targets_rotation"
    t.index ["job_id", "is_active", "lease_expires_at", "last_searched_at"], name: "idx_job_targets_lease_rotation"
    t.index ["job_id"], name: "index_job_targets_on_job_id"
    t.check_constraint "country_city_id IS NOT NULL AND custom_city_name IS NULL OR country_city_id IS NULL AND custom_city_name IS NOT NULL", name: "chk_job_targets_mutually_exclusive_city"
  end

  create_table "jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "active_weekdays", default: [1, 2, 3, 4, 5], null: false, array: true
    t.timestamptz "archived_at"
    t.datetime "created_at", null: false
    t.integer "daily_discovery_target", default: 50, null: false
    t.integer "daily_outreach_target", default: 0, null: false
    t.string "discovery_schedule", limit: 64, default: "0 8 * * *", null: false
    t.time "discovery_window_end", default: "2000-01-01 20:00:00", null: false
    t.time "discovery_window_start", default: "2000-01-01 08:00:00", null: false
    t.timestamptz "last_discovery_at"
    t.timestamptz "last_outreach_at"
    t.text "message_template", null: false
    t.string "name", limit: 255, null: false
    t.timestamptz "next_discovery_at"
    t.integer "outreach_interval_seconds", default: 120, null: false
    t.string "outreach_mode", limit: 32, default: "manual_review", null: false
    t.time "outreach_window_end", default: "2000-01-01 17:00:00", null: false
    t.time "outreach_window_start", default: "2000-01-01 09:00:00", null: false
    t.uuid "prospecting_profile_id"
    t.string "status", limit: 32, default: "draft", null: false
    t.string "timezone", limit: 64, default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.string "website_targeting", limit: 32, default: "both", null: false
    t.index ["prospecting_profile_id"], name: "index_jobs_on_prospecting_profile_id"
    t.index ["status", "next_discovery_at"], name: "idx_jobs_active_discovery_poll", where: "((status)::text = 'active'::text)"
    t.index ["status"], name: "index_jobs_on_status"
    t.index ["user_id"], name: "index_jobs_on_user_id"
    t.check_constraint "daily_discovery_target > 0 AND daily_discovery_target <= 500", name: "chk_jobs_daily_discovery"
    t.check_constraint "daily_outreach_target >= 0 AND daily_outreach_target <= 100", name: "chk_jobs_daily_outreach"
    t.check_constraint "outreach_interval_seconds >= 60", name: "chk_jobs_outreach_interval"
    t.check_constraint "outreach_mode::text = ANY (ARRAY['manual_review'::character varying, 'automatic'::character varying]::text[])", name: "chk_jobs_outreach_mode"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'active'::character varying, 'paused'::character varying, 'completed'::character varying, 'archived'::character varying]::text[])", name: "chk_jobs_status"
    t.check_constraint "website_targeting::text = ANY (ARRAY['no_website'::character varying, 'weak_or_outdated'::character varying, 'both'::character varying]::text[])", name: "chk_jobs_website_targeting"
  end

  create_table "outreach_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "length", default: "Short", null: false
    t.text "message", null: false
    t.uuid "prospecting_profile_id", null: false
    t.uuid "search_result_id", null: false
    t.string "tone", default: "Professional", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.string "whatsapp_url", null: false
    t.index ["prospecting_profile_id"], name: "index_outreach_messages_on_prospecting_profile_id"
    t.index ["search_result_id", "prospecting_profile_id", "tone", "length"], name: "idx_outreach_msgs_lookup"
    t.index ["search_result_id"], name: "index_outreach_messages_on_search_result_id"
    t.index ["user_id"], name: "index_outreach_messages_on_user_id"
  end

  create_table "outreach_tasks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "attempt_count", default: 0, null: false
    t.timestamptz "completed_at"
    t.datetime "created_at", null: false
    t.string "destination_phone", limit: 32, null: false
    t.string "dispatch_token_digest", limit: 64
    t.timestamptz "dispatch_token_expires_at"
    t.timestamptz "dispatched_at"
    t.string "error_code", limit: 64
    t.text "error_details"
    t.uuid "extension_device_id"
    t.string "idempotency_key", limit: 128, null: false
    t.uuid "job_id", null: false
    t.uuid "job_prospect_id", null: false
    t.text "prepared_message", null: false
    t.timestamptz "scheduled_for", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamptz "sending_at"
    t.string "status", limit: 32, default: "queued", null: false
    t.datetime "updated_at", null: false
    t.text "whatsapp_url", null: false
    t.index ["dispatch_token_digest"], name: "idx_outreach_tasks_dispatch_token", where: "(dispatch_token_digest IS NOT NULL)"
    t.index ["extension_device_id"], name: "index_outreach_tasks_on_extension_device_id"
    t.index ["idempotency_key"], name: "index_outreach_tasks_on_idempotency_key", unique: true
    t.index ["job_id", "status", "scheduled_for"], name: "idx_outreach_tasks_poll", where: "((status)::text = ANY ((ARRAY['queued'::character varying, 'retrying'::character varying])::text[]))"
    t.index ["job_id"], name: "index_outreach_tasks_on_job_id"
    t.index ["job_prospect_id"], name: "index_outreach_tasks_on_job_prospect_id"
    t.check_constraint "attempt_count >= 0", name: "chk_outreach_tasks_attempt_count"
    t.check_constraint "status::text = ANY (ARRAY['pending_review'::character varying, 'approved'::character varying, 'queued'::character varying, 'dispatched'::character varying, 'sending'::character varying, 'sent'::character varying, 'failed'::character varying, 'uncertain'::character varying, 'skipped'::character varying, 'cancelled'::character varying, 'retrying'::character varying]::text[])", name: "chk_outreach_tasks_status"
  end

  create_table "prospecting_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "contact_signals", default: []
    t.datetime "created_at", null: false
    t.boolean "is_default", default: false, null: false
    t.string "name", null: false
    t.jsonb "opportunity_signals", default: []
    t.string "service", null: false
    t.text "service_description", null: false
    t.jsonb "target_businesses", default: []
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "is_default"], name: "index_prospecting_profiles_on_user_id_and_is_default"
    t.index ["user_id"], name: "index_prospecting_profiles_on_user_id"
  end

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

  create_table "qr_scans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "prospecting_profile_id"
    t.datetime "scanned_at", null: false
    t.uuid "search_id"
    t.uuid "search_result_id", null: false
    t.datetime "updated_at", null: false
    t.index ["prospecting_profile_id"], name: "index_qr_scans_on_prospecting_profile_id"
    t.index ["search_id"], name: "index_qr_scans_on_search_id"
    t.index ["search_result_id", "scanned_at"], name: "index_qr_scans_on_search_result_id_and_scanned_at"
    t.index ["search_result_id"], name: "index_qr_scans_on_search_result_id"
  end

  create_table "quota_reservations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "amount", default: 1, null: false
    t.datetime "created_at", null: false
    t.timestamptz "expires_at", null: false
    t.uuid "job_id", null: false
    t.string "quota_type", limit: 32, null: false
    t.string "reservation_key", limit: 128, null: false
    t.date "stat_date", null: false
    t.string "status", limit: 32, default: "reserved", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "quota_type", "stat_date", "status"], name: "idx_quota_reservations_active"
    t.index ["job_id"], name: "index_quota_reservations_on_job_id"
    t.index ["reservation_key"], name: "index_quota_reservations_on_reservation_key", unique: true
    t.check_constraint "amount > 0", name: "chk_quota_reservations_amount"
    t.check_constraint "quota_type::text = ANY (ARRAY['discovery'::character varying, 'outreach'::character varying]::text[])", name: "chk_quota_reservations_type"
    t.check_constraint "status::text = ANY (ARRAY['reserved'::character varying, 'consumed'::character varying, 'released'::character varying, 'expired'::character varying]::text[])", name: "chk_quota_reservations_status"
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
    t.string "qr_token"
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
    t.index ["qr_token"], name: "index_search_results_on_qr_token", unique: true
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
    t.uuid "prospecting_profile_id"
    t.text "qr_message_template"
    t.string "query"
    t.integer "results_count", default: 0, null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.string "website_filter"
    t.index ["created_at"], name: "index_searches_on_created_at"
    t.index ["prospecting_profile_id"], name: "index_searches_on_prospecting_profile_id"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ai_length", default: "Short", null: false
    t.string "ai_tone", default: "Professional", null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest"
    t.string "provider"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token_digest"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.datetime "verification_sent_at"
    t.string "verification_token_digest"
    t.datetime "verified_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token_digest"], name: "index_users_on_reset_password_token_digest"
    t.index ["verification_token_digest"], name: "index_users_on_verification_token_digest"
  end

  add_foreign_key "country_cities", "countries", on_delete: :restrict
  add_foreign_key "extension_devices", "users", on_delete: :cascade
  add_foreign_key "job_daily_stats", "jobs", on_delete: :cascade
  add_foreign_key "job_prospects", "jobs", on_delete: :cascade
  add_foreign_key "job_prospects", "prospects", on_delete: :cascade
  add_foreign_key "job_prospects", "search_results", on_delete: :nullify
  add_foreign_key "job_targets", "countries", on_delete: :restrict
  add_foreign_key "job_targets", "country_cities", on_delete: :restrict
  add_foreign_key "job_targets", "jobs", on_delete: :cascade
  add_foreign_key "jobs", "prospecting_profiles", on_delete: :nullify
  add_foreign_key "jobs", "users", on_delete: :cascade
  add_foreign_key "outreach_messages", "prospecting_profiles", on_delete: :cascade
  add_foreign_key "outreach_messages", "search_results", on_delete: :cascade
  add_foreign_key "outreach_messages", "users", on_delete: :cascade
  add_foreign_key "outreach_tasks", "extension_devices", on_delete: :nullify
  add_foreign_key "outreach_tasks", "job_prospects", on_delete: :restrict
  add_foreign_key "outreach_tasks", "jobs", on_delete: :restrict
  add_foreign_key "prospecting_profiles", "users", on_delete: :cascade
  add_foreign_key "prospects", "users", on_delete: :cascade
  add_foreign_key "qr_scans", "prospecting_profiles", on_delete: :cascade
  add_foreign_key "qr_scans", "search_results", on_delete: :cascade
  add_foreign_key "qr_scans", "searches", on_delete: :cascade
  add_foreign_key "quota_reservations", "jobs", on_delete: :cascade
  add_foreign_key "search_results", "searches", on_delete: :cascade
  add_foreign_key "search_results", "users", on_delete: :cascade
  add_foreign_key "searches", "prospecting_profiles", on_delete: :nullify
  add_foreign_key "searches", "users", on_delete: :cascade
end
