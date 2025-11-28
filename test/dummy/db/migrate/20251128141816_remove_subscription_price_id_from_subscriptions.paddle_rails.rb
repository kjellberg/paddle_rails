# This migration comes from paddle_rails (originally 20251128151453)
class RemoveSubscriptionPriceIdFromSubscriptions < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :paddle_rails_subscriptions, :paddle_rails_subscription_prices, if_exists: true
    remove_index :paddle_rails_subscriptions, :subscription_price_id, if_exists: true
    remove_column :paddle_rails_subscriptions, :subscription_price_id, :integer, if_exists: true
  end
end

