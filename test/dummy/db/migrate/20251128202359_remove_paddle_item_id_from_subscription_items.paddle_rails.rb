# This migration comes from paddle_rails (originally 20251128152025)
class RemovePaddleItemIdFromSubscriptionItems < ActiveRecord::Migration[8.1]
  def change
    remove_column :paddle_rails_subscription_items, :paddle_item_id, :string, if_exists: true
  end
end

