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

ActiveRecord::Schema[7.1].define(version: 2026_02_26_174500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "availability_slots", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "dow"
    t.integer "start_min"
    t.integer "end_min"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location_name"
    t.index ["user_id"], name: "index_availability_slots_on_user_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "match_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "reminder_enabled", default: true, null: false
    t.integer "reminder_minutes_before", default: 60, null: false
    t.bigint "buddy_id"
    t.bigint "creator_id", null: false
    t.integer "buddy_status", default: 0, null: false
    t.index ["buddy_id"], name: "index_bookings_on_buddy_id"
    t.index ["creator_id"], name: "index_bookings_on_creator_id"
    t.index ["match_id"], name: "index_bookings_on_match_id"
  end

  create_table "group_members", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_members_on_group_id"
    t.index ["user_id"], name: "index_group_members_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.integer "band"
    t.boolean "women_only"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "match_decisions", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.bigint "user_id", null: false
    t.integer "decision", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_match_decisions_on_match_id"
    t.index ["user_id"], name: "index_match_decisions_on_user_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "user_a_id", null: false
    t.bigint "user_b_id", null: false
    t.float "score"
    t.integer "status"
    t.jsonb "overlap_windows_json", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_a_id", "user_b_id"], name: "index_matches_on_user_a_id_and_user_b_id", unique: true
    t.index ["user_a_id"], name: "index_matches_on_user_a_id"
    t.index ["user_b_id"], name: "index_matches_on_user_b_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "age_range"
    t.string "gender"
    t.string "gym"
    t.integer "experience_band"
    t.string "goals", default: [], array: true
    t.boolean "women_only", default: false, null: false
    t.boolean "same_gym_only", default: false, null: false
    t.integer "minimum_weekly_overlap_minutes", default: 90, null: false
    t.jsonb "privacy_matrix", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "age"
    t.string "home_gym_name"
    t.string "home_city"
    t.string "travel_preference", default: "flexible", null: false
    t.integer "preferred_partner_age_min"
    t.integer "preferred_partner_age_max"
    t.string "preferred_buddy_days", default: [], null: false, array: true
    t.string "preferred_buddy_times", default: [], null: false, array: true
    t.string "gym_postcode"
    t.decimal "gym_latitude", precision: 10, scale: 6
    t.decimal "gym_longitude", precision: 10, scale: 6
    t.integer "match_radius_miles", default: 50, null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "prs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "exercise"
    t.decimal "value"
    t.string "unit"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_prs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pilot_updates", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workout_comments", force: :cascade do |t|
    t.bigint "workout_log_id", null: false
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_workout_comments_on_author_id"
    t.index ["workout_log_id"], name: "index_workout_comments_on_workout_log_id"
  end

  create_table "workout_kudos", force: :cascade do |t|
    t.bigint "workout_log_id", null: false
    t.bigint "giver_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["giver_id"], name: "index_workout_kudos_on_giver_id"
    t.index ["workout_log_id", "giver_id"], name: "index_workout_kudos_on_workout_log_id_and_giver_id", unique: true
    t.index ["workout_log_id"], name: "index_workout_kudos_on_workout_log_id"
  end

  create_table "workout_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date"
    t.integer "kind"
    t.jsonb "payload_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.jsonb "exercises", default: [], null: false
    t.boolean "shared_with_buddies", default: false, null: false
    t.boolean "contains_pr", default: false, null: false
    t.text "notes"
    t.datetime "shared_at"
    t.index ["user_id"], name: "index_workout_logs_on_user_id"
  end

  create_table "workout_reactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "workout_log_id", null: false
    t.string "kind", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "workout_log_id"], name: "index_workout_reactions_on_user_log_kudos", unique: true, where: "((kind)::text = 'kudos'::text)"
    t.index ["user_id"], name: "index_workout_reactions_on_user_id"
    t.index ["workout_log_id"], name: "index_workout_reactions_on_workout_log_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "availability_slots", "users"
  add_foreign_key "bookings", "users", column: "buddy_id"
  add_foreign_key "bookings", "users", column: "creator_id"
  add_foreign_key "group_members", "groups"
  add_foreign_key "group_members", "users"
  add_foreign_key "match_decisions", "matches"
  add_foreign_key "match_decisions", "users"
  add_foreign_key "matches", "users", column: "user_a_id"
  add_foreign_key "matches", "users", column: "user_b_id"
  add_foreign_key "profiles", "users"
  add_foreign_key "prs", "users"
  add_foreign_key "workout_comments", "users", column: "author_id"
  add_foreign_key "workout_comments", "workout_logs"
  add_foreign_key "workout_kudos", "users", column: "giver_id"
  add_foreign_key "workout_kudos", "workout_logs"
  add_foreign_key "workout_logs", "users"
  add_foreign_key "workout_reactions", "users"
  add_foreign_key "workout_reactions", "workout_logs"
end
