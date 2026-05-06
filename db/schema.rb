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

ActiveRecord::Schema[7.2].define(version: 5) do
  create_table "bookings", force: :cascade do |t|
    t.string "confirmation_code", null: false
    t.integer "seats_reserved", null: false
    t.decimal "total_price_amount", precision: 10, scale: 2
    t.string "total_price_currency", default: "USD"
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "event_id", null: false
    t.string "ticket_type"
    t.index ["event_id"], name: "index_bookings_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.integer "total_seats", null: false
    t.integer "available_seats", null: false
    t.decimal "base_price_amount", precision: 10, scale: 2
    t.string "base_price_currency", default: "USD"
    t.integer "venue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_events_on_name"
    t.index ["start_time"], name: "index_events_on_start_time"
    t.index ["venue_id"], name: "index_events_on_venue_id"
  end

  create_table "venues", force: :cascade do |t|
    t.string "name", null: false
    t.string "address"
    t.integer "capacity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_venues_on_name"
  end

  add_foreign_key "bookings", "events"
  add_foreign_key "events", "venues"
end
