# This migration comes from paddle_rails (originally 20251124180817)
class CreatePaddleRailsSubscriptionPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :paddle_rails_subscription_prices do |t|
      t.references :subscription_plan, null: false, foreign_key: { to_table: :paddle_rails_subscription_plans }
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
    end

    add_index :paddle_rails_subscription_prices, :paddle_price_id, unique: true
  end
end
