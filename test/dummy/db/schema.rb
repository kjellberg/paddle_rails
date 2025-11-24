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

ActiveRecord::Schema[8.1].define(version: 2025_11_24_185709) do
  create_table "paddle_rails_subscription_plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "custom_data"
    t.text "description"
    t.string "image_url"
    t.string "name"
    t.string "paddle_product_id", null: false
    t.string "status"
    t.string "tax_category"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["paddle_product_id"], name: "index_paddle_rails_subscription_plans_on_paddle_product_id", unique: true
  end

  create_table "paddle_rails_subscription_prices", force: :cascade do |t|
    t.string "billing_interval"
    t.integer "billing_interval_count"
    t.datetime "created_at", null: false
    t.string "currency"
    t.json "custom_data"
    t.text "description"
    t.string "name"
    t.string "paddle_price_id", null: false
    t.integer "quantity_maximum"
    t.integer "quantity_minimum"
    t.string "status"
    t.integer "subscription_plan_id", null: false
    t.string "tax_mode"
    t.integer "trial_days"
    t.json "trial_period"
    t.string "type"
    t.integer "unit_price"
    t.datetime "updated_at", null: false
    t.index ["paddle_price_id"], name: "index_paddle_rails_subscription_prices_on_paddle_price_id", unique: true
    t.index ["subscription_plan_id"], name: "index_paddle_rails_subscription_prices_on_subscription_plan_id"
  end

  add_foreign_key "paddle_rails_subscription_prices", "paddle_rails_subscription_plans", column: "subscription_plan_id"
end
