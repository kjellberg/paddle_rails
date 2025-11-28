class RenameSubscriptionProductIdToProductIdInPrices < ActiveRecord::Migration[8.1]
  def change
    # Remove old foreign key
    remove_foreign_key :paddle_rails_prices, :paddle_rails_subscription_products, if_exists: true
    
    # Rename the column
    rename_column :paddle_rails_prices, :subscription_product_id, :product_id
    
    # Add new foreign key
    add_foreign_key :paddle_rails_prices, :paddle_rails_products, column: :product_id
  end
end

