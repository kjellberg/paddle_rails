class RenameSubscriptionPlansToProducts < ActiveRecord::Migration[8.1]
  def change
    rename_table :paddle_rails_subscription_plans, :paddle_rails_subscription_products
  end
end

