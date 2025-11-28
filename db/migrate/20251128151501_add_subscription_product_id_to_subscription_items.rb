class AddSubscriptionProductIdToSubscriptionItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :paddle_rails_subscription_items, :subscription_product, 
                  foreign_key: { to_table: :paddle_rails_subscription_products }, 
                  index: true
  end
end

