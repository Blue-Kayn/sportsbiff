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

ActiveRecord::Schema[8.0].define(version: 2025_12_28_204931) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chats", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.string "sport"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "team_id"
    t.boolean "is_team_channel", default: false, null: false
    t.index ["user_id", "team_id"], name: "index_chats_on_user_id_and_team_id", unique: true, where: "(team_id IS NOT NULL)"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.string "role"
    t.text "content"
    t.integer "tokens_used"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "odds_caches", force: :cascade do |t|
    t.string "sport"
    t.string "event_id"
    t.jsonb "data"
    t.datetime "fetched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_odds_caches_on_event_id"
    t.index ["sport", "event_id"], name: "index_odds_caches_on_sport_and_event_id", unique: true
    t.index ["sport"], name: "index_odds_caches_on_sport"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.string "sport", null: false
    t.string "api_id", null: false
    t.jsonb "colors", default: {}
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_id"], name: "index_teams_on_api_id", unique: true
    t.index ["sport", "name"], name: "index_teams_on_sport_and_name", unique: true
    t.index ["sport"], name: "index_teams_on_sport"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "daily_query_count", default: 0, null: false
    t.date "query_count_reset_date"
    t.string "subscription_tier", default: "free", null: false
    t.jsonb "favorite_sports", default: [], null: false
    t.jsonb "favorite_teams", default: [], null: false
    t.boolean "onboarded", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "chats", "users"
  add_foreign_key "messages", "chats"
end
