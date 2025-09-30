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

ActiveRecord::Schema[7.2].define(version: 2025_09_30_043612) do
  create_schema "auth"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_graphql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "supabase_vault"
  enable_extension "uuid-ossp"
  enable_extension "vector"

  create_table "contacts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "hubspot_id"
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_contacts_on_name"
    t.index ["user_id", "email"], name: "index_contacts_on_user_id_and_email"
    t.index ["user_id", "hubspot_id"], name: "index_contacts_on_user_id_and_hubspot_id", unique: true
    t.index ["user_id"], name: "index_contacts_on_user_id"
  end

  create_table "credentials", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "provider"], name: "index_credentials_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_credentials_on_user_id"
  end

  create_table "embeddings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.string "ref_id", null: false
    t.text "chunk", null: false
    t.vector "embedding", limit: 1536
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["embedding"], name: "index_embeddings_on_embedding_ivfflat_cosine", opclass: :vector_cosine_ops, using: :ivfflat
    t.index ["kind"], name: "index_embeddings_on_kind"
    t.index ["user_id", "kind", "ref_id"], name: "index_embeddings_on_user_id_and_kind_and_ref_id", unique: true
    t.index ["user_id"], name: "index_embeddings_on_user_id"
  end

  create_table "instructions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "rule_text", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "is_active"], name: "index_instructions_on_user_id_and_is_active"
    t.index ["user_id"], name: "index_instructions_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "source", null: false
    t.string "ext_id", null: false
    t.string "thread_id"
    t.string "subject"
    t.string "sender"
    t.datetime "sent_at"
    t.text "body_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sent_at"], name: "index_messages_on_sent_at"
    t.index ["thread_id"], name: "index_messages_on_thread_id"
    t.index ["user_id", "source", "ext_id"], name: "index_messages_on_user_id_and_source_and_ext_id", unique: true
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "source", null: false
    t.string "ext_id"
    t.bigint "contact_id"
    t.text "body_text"
    t.datetime "created_at_ext"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_notes_on_contact_id"
    t.index ["created_at_ext"], name: "index_notes_on_created_at_ext"
    t.index ["user_id", "source", "ext_id"], name: "index_notes_on_user_id_and_source_and_ext_id", unique: true
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.text "payload_json", null: false
    t.string "status", default: "pending", null: false
    t.text "last_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_tasks_on_kind"
    t.index ["user_id", "status"], name: "index_tasks_on_user_id_and_status"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.text "google_access_token"
    t.text "google_refresh_token"
    t.datetime "google_expires_at"
    t.string "google_token_type"
    t.string "google_scope"
    t.text "hubspot_access_token"
    t.text "hubspot_refresh_token"
    t.datetime "hubspot_expires_at"
    t.string "hubspot_token_type"
    t.string "hubspot_scope"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "contacts", "users"
  add_foreign_key "credentials", "users"
  add_foreign_key "embeddings", "users"
  add_foreign_key "instructions", "users"
  add_foreign_key "messages", "users"
  add_foreign_key "notes", "contacts"
  add_foreign_key "notes", "users"
  add_foreign_key "tasks", "users"
end
