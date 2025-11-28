# This migration comes from paddle_rails (originally 20251128212046)
class RenameSubscriptionProductsToProducts < ActiveRecord::Migration[8.1]
  def change
    rename_table :paddle_rails_subscription_products, :paddle_rails_products
  end
end

