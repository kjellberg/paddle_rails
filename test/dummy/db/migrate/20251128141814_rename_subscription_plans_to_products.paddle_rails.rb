# This migration comes from paddle_rails (originally 20251128151401)
class RenameSubscriptionPlansToProducts < ActiveRecord::Migration[8.1]
  def change
    rename_table :paddle_rails_subscription_plans, :paddle_rails_subscription_products
  end
end

