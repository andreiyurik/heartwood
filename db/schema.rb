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

ActiveRecord::Schema[8.1].define(version: 2026_06_10_120055) do
  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_end"
    t.string "date_precision"
    t.string "date_raw"
    t.date "date_start"
    t.integer "eventable_id", null: false
    t.string "eventable_type", null: false
    t.string "kind"
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["eventable_type", "eventable_id"], name: "index_events_on_eventable"
  end

  create_table "families", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "gedcom_xref"
    t.datetime "updated_at", null: false
  end

  create_table "family_children", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "family_id", null: false
    t.string "pedigree"
    t.integer "person_id", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_family_children_on_family_id"
    t.index ["person_id"], name: "index_family_children_on_person_id"
  end

  create_table "family_partners", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "family_id", null: false
    t.integer "person_id", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_family_partners_on_family_id"
    t.index ["person_id"], name: "index_family_partners_on_person_id"
  end

  create_table "people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "gedcom_xref"
    t.string "given_names"
    t.string "name_prefix"
    t.string "name_suffix"
    t.string "nickname"
    t.string "sex", default: "U", null: false
    t.string "surname"
    t.datetime "updated_at", null: false
    t.index ["gedcom_xref"], name: "index_people_on_gedcom_xref"
  end

  add_foreign_key "family_children", "families"
  add_foreign_key "family_children", "people"
  add_foreign_key "family_partners", "families"
  add_foreign_key "family_partners", "people"
end
