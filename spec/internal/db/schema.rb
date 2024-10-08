# frozen_string_literal: true

ActiveRecord::Schema.define(version: 20231010123456) do
  create_table "apps", force: :cascade do |t|
    t.string "name"
    t.timestamps
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.timestamps
  end

  create_table "events", force: :cascade do |t|
    t.integer "app_id"
    t.integer "customer_id"
    t.string "event_name"
    t.string "event_type"
    t.string "event_value"
    t.jsonb "payload", default: {}
    t.datetime "timestamp"
    t.timestamps
  end

  add_foreign_key "events", "apps"
  add_foreign_key "events", "customers"
end
