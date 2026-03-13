class CreatePaddleRailsTables < ActiveRecord::Migration[8.1]
  def change
    create_table :paddle_rails_products do |t|
      t.string :paddle_product_id, null: false
      t.string :name
      t.text :description
      t.string :status
      t.string :type
      t.string :tax_category
      t.string :image_url
      t.json :custom_data
      t.timestamps
      t.index :paddle_product_id, unique: true
    end

    create_table :paddle_rails_prices do |t|
      t.references :product, null: false, foreign_key: { to_table: :paddle_rails_products }
      t.string :paddle_price_id, null: false
      t.string :currency
      t.integer :unit_price
      t.string :billing_interval
      t.integer :billing_interval_count
      t.integer :trial_days
      t.string :type
      t.string :name
      t.text :description
      t.string :status
      t.string :tax_mode
      t.integer :quantity_minimum
      t.integer :quantity_maximum
      t.json :trial_period
      t.json :custom_data
      t.timestamps
      t.index :paddle_price_id, unique: true
    end

    create_table :paddle_rails_subscriptions do |t|
      t.references :owner, polymorphic: true, null: false
      t.string :paddle_subscription_id, null: false
      t.string :status
      t.datetime :current_period_end_at
      t.datetime :trial_ends_at
      t.datetime :scheduled_cancelation_at
      t.string :payment_method_id
      t.string :payment_method_type
      t.json :payment_method_details
      t.json :raw_payload
      t.timestamps
      t.index :paddle_subscription_id, unique: true
      t.index :status
      t.index :payment_method_id
    end

    create_table :paddle_rails_subscription_items do |t|
      t.references :subscription, null: false, foreign_key: { to_table: :paddle_rails_subscriptions }
      t.references :price, null: false, foreign_key: { to_table: :paddle_rails_prices }
      t.references :product, foreign_key: { to_table: :paddle_rails_products }
      t.integer :quantity, default: 1
      t.string :status
      t.boolean :recurring, default: false
      t.timestamps
      t.index [ :subscription_id, :price_id ], unique: true, name: "index_subscription_items_on_subscription_and_price"
    end

    create_table :paddle_rails_webhook_events do |t|
      t.string :external_id, null: false
      t.string :event_type, null: false
      t.json :payload, null: false
      t.string :status, null: false, default: "pending"
      t.text :processing_errors
      t.datetime :processed_at
      t.timestamps
      t.index :external_id, unique: true
      t.index :event_type
      t.index :status
    end

    create_table :paddle_rails_payments do |t|
      t.references :subscription, null: false, foreign_key: { to_table: :paddle_rails_subscriptions }
      t.references :owner, polymorphic: true, null: false
      t.string :paddle_transaction_id, null: false
      t.string :invoice_id
      t.string :invoice_number
      t.string :status, null: false
      t.string :origin
      t.integer :total
      t.integer :tax
      t.integer :subtotal
      t.string :currency
      t.datetime :billed_at
      t.json :details
      t.json :raw_payload
      t.timestamps
      t.index :paddle_transaction_id, unique: true
    end
  end
end
