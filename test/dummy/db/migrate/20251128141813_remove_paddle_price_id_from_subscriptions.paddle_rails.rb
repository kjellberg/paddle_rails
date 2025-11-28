# This migration comes from paddle_rails (originally 20251128151334)
class RemovePaddlePriceIdFromSubscriptions < ActiveRecord::Migration[8.1]
  def change
    remove_index :paddle_rails_subscriptions, :paddle_price_id, if_exists: true
    remove_column :paddle_rails_subscriptions, :paddle_price_id, :string, if_exists: true
  end
end

