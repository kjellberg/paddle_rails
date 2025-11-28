# This migration comes from paddle_rails (originally 20251128212054)
class RenameFksInSubscriptionItems < ActiveRecord::Migration[8.1]
  def change
    # Remove old foreign keys
    remove_foreign_key :paddle_rails_subscription_items, :paddle_rails_subscription_prices, if_exists: true
    remove_foreign_key :paddle_rails_subscription_items, :paddle_rails_subscription_products, if_exists: true
    
    # Rename the columns
    rename_column :paddle_rails_subscription_items, :subscription_price_id, :price_id
    rename_column :paddle_rails_subscription_items, :subscription_product_id, :product_id
    
    # Update the unique index
    remove_index :paddle_rails_subscription_items, name: "index_subscription_items_on_subscription_and_price", if_exists: true
    add_index :paddle_rails_subscription_items, [:subscription_id, :price_id], unique: true, name: "index_subscription_items_on_subscription_and_price"
    
    # Add new foreign keys
    add_foreign_key :paddle_rails_subscription_items, :paddle_rails_prices, column: :price_id
    add_foreign_key :paddle_rails_subscription_items, :paddle_rails_products, column: :product_id
  end
end

