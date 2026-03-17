class AddMissingConstraintsAndIndexesToPaddleRails < ActiveRecord::Migration[8.1]
  def change
    # Add NOT NULL constraints on status columns
    change_column_null :paddle_rails_products, :status, false, "active"
    change_column_null :paddle_rails_prices, :status, false, "active"
    change_column_null :paddle_rails_subscriptions, :status, false, "active"
    change_column_null :paddle_rails_subscription_items, :status, false, "active"

    # Add missing indexes for columns queried by scopes/joins
    add_index :paddle_rails_payments, :status
    add_index :paddle_rails_subscription_items, :status
    add_index :paddle_rails_prices, :status
  end
end
