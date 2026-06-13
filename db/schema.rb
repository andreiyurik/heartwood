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

ActiveRecord::Schema[8.1].define(version: 2026_06_13_123041) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "citations", force: :cascade do |t|
    t.integer "citable_id", null: false
    t.string "citable_type", null: false
    t.datetime "created_at", null: false
    t.integer "source_id", null: false
    t.datetime "updated_at", null: false
    t.index ["citable_type", "citable_id"], name: "index_citations_on_citable"
    t.index ["source_id"], name: "index_citations_on_source_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_end"
    t.string "date_precision"
    t.string "date_raw"
    t.date "date_start"
    t.integer "eventable_id", null: false
    t.string "eventable_type", null: false
    t.json "gedcom_raw"
    t.string "gedcom_xref"
    t.string "kind"
    t.integer "tree_id", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["eventable_type", "eventable_id"], name: "index_events_on_eventable"
    t.index ["tree_id"], name: "index_events_on_tree_id"
  end

  create_table "families", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "gedcom_raw"
    t.string "gedcom_xref"
    t.integer "tree_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tree_id"], name: "index_families_on_tree_id"
  end

  create_table "family_children", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "family_id", null: false
    t.string "pedigree"
    t.integer "person_id", null: false
    t.integer "position"
    t.integer "tree_id", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_family_children_on_family_id"
    t.index ["person_id"], name: "index_family_children_on_person_id"
    t.index ["tree_id"], name: "index_family_children_on_tree_id"
  end

  create_table "family_partners", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "family_id", null: false
    t.integer "person_id", null: false
    t.string "role"
    t.integer "tree_id", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_family_partners_on_family_id"
    t.index ["person_id"], name: "index_family_partners_on_person_id"
    t.index ["tree_id"], name: "index_family_partners_on_tree_id"
  end

  create_table "people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "gedcom_raw"
    t.string "gedcom_xref"
    t.string "given_names"
    t.string "name_prefix"
    t.string "name_suffix"
    t.string "nickname"
    t.boolean "private", default: false, null: false
    t.string "sex", default: "U", null: false
    t.string "surname"
    t.integer "tree_id", null: false
    t.datetime "updated_at", null: false
    t.index ["gedcom_xref"], name: "index_people_on_gedcom_xref"
    t.index ["tree_id"], name: "index_people_on_tree_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sources", force: :cascade do |t|
    t.text "citation_text"
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.integer "tree_id", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["tree_id"], name: "index_sources_on_tree_id"
  end

  create_table "tree_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", default: "owner", null: false
    t.integer "tree_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["tree_id", "user_id"], name: "index_tree_memberships_on_tree_id_and_user_id", unique: true
    t.index ["tree_id"], name: "index_tree_memberships_on_tree_id"
    t.index ["user_id"], name: "index_tree_memberships_on_user_id"
    t.index ["user_id"], name: "index_tree_memberships_unique_owner_per_user", unique: true, where: "role = 'owner'"
  end

  create_table "trees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "citations", "sources"
  add_foreign_key "events", "trees"
  add_foreign_key "families", "trees"
  add_foreign_key "family_children", "families"
  add_foreign_key "family_children", "people"
  add_foreign_key "family_children", "trees"
  add_foreign_key "family_partners", "families"
  add_foreign_key "family_partners", "people"
  add_foreign_key "family_partners", "trees"
  add_foreign_key "people", "trees"
  add_foreign_key "sessions", "users"
  add_foreign_key "sources", "trees"
  add_foreign_key "tree_memberships", "trees"
  add_foreign_key "tree_memberships", "users"
end
