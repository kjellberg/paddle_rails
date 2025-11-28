class RenameSubscriptionPlanIdToSubscriptionProductId < ActiveRecord::Migration[8.1]
  def change
    # Remove old foreign key
    remove_foreign_key :paddle_rails_subscription_prices, :paddle_rails_subscription_plans if foreign_key_exists?(:paddle_rails_subscription_prices, :paddle_rails_subscription_plans)
    
    # Rename the column
    rename_column :paddle_rails_subscription_prices, :subscription_plan_id, :subscription_product_id
    
    # Add new foreign key
    add_foreign_key :paddle_rails_subscription_prices, :paddle_rails_subscription_products, column: :subscription_product_id
  end
end

