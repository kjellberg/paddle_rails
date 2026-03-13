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

ActiveRecord::Schema[8.1].define(version: 2025_11_24_224102) do
  create_table "paddle_rails_payments", force: :cascade do |t|
    t.datetime "billed_at"
    t.datetime "created_at", null: false
    t.string "currency"
    t.json "details"
    t.string "invoice_id"
    t.string "invoice_number"
    t.string "origin"
    t.integer "owner_id", null: false
    t.string "owner_type", null: false
    t.string "paddle_transaction_id", null: false
    t.json "raw_payload"
    t.string "status", null: false
    t.integer "subscription_id", null: false
    t.integer "subtotal"
    t.integer "tax"
    t.integer "total"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_paddle_rails_payments_on_owner"
    t.index ["paddle_transaction_id"], name: "index_paddle_rails_payments_on_paddle_transaction_id", unique: true
    t.index ["subscription_id"], name: "index_paddle_rails_payments_on_subscription_id"
  end

  create_table "paddle_rails_prices", force: :cascade do |t|
    t.string "billing_interval"
    t.integer "billing_interval_count"
    t.datetime "created_at", null: false
    t.string "currency"
    t.json "custom_data"
    t.text "description"
    t.string "name"
    t.string "paddle_price_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity_maximum"
    t.integer "quantity_minimum"
    t.string "status"
    t.string "tax_mode"
    t.integer "trial_days"
    t.json "trial_period"
    t.string "type"
    t.integer "unit_price"
    t.datetime "updated_at", null: false
    t.index ["paddle_price_id"], name: "index_paddle_rails_prices_on_paddle_price_id", unique: true
    t.index ["product_id"], name: "index_paddle_rails_prices_on_product_id"
  end

  create_table "paddle_rails_products", force: :cascade do |t|
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
    t.index ["paddle_product_id"], name: "index_paddle_rails_products_on_paddle_product_id", unique: true
  end

  create_table "paddle_rails_subscription_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "price_id", null: false
    t.integer "product_id"
    t.integer "quantity", default: 1
    t.boolean "recurring", default: false
    t.string "status"
    t.integer "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["price_id"], name: "index_paddle_rails_subscription_items_on_price_id"
    t.index ["product_id"], name: "index_paddle_rails_subscription_items_on_product_id"
    t.index ["subscription_id", "price_id"], name: "index_subscription_items_on_subscription_and_price", unique: true
    t.index ["subscription_id"], name: "index_paddle_rails_subscription_items_on_subscription_id"
  end

  create_table "paddle_rails_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_period_end_at"
    t.integer "owner_id", null: false
    t.string "owner_type", null: false
    t.string "paddle_subscription_id", null: false
    t.json "payment_method_details"
    t.string "payment_method_id"
    t.string "payment_method_type"
    t.json "raw_payload"
    t.datetime "scheduled_cancelation_at"
    t.string "status"
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_paddle_rails_subscriptions_on_owner"
    t.index ["paddle_subscription_id"], name: "index_paddle_rails_subscriptions_on_paddle_subscription_id", unique: true
    t.index ["payment_method_id"], name: "index_paddle_rails_subscriptions_on_payment_method_id"
    t.index ["status"], name: "index_paddle_rails_subscriptions_on_status"
  end

  create_table "paddle_rails_webhook_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "external_id", null: false
    t.json "payload", null: false
    t.datetime "processed_at"
    t.text "processing_errors"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_paddle_rails_webhook_events_on_event_type"
    t.index ["external_id"], name: "index_paddle_rails_webhook_events_on_external_id", unique: true
    t.index ["status"], name: "index_paddle_rails_webhook_events_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "paddle_rails_payments", "paddle_rails_subscriptions", column: "subscription_id"
  add_foreign_key "paddle_rails_prices", "paddle_rails_products", column: "product_id"
  add_foreign_key "paddle_rails_subscription_items", "paddle_rails_prices", column: "price_id"
  add_foreign_key "paddle_rails_subscription_items", "paddle_rails_products", column: "product_id"
  add_foreign_key "paddle_rails_subscription_items", "paddle_rails_subscriptions", column: "subscription_id"
end
