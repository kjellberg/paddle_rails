class CreatePaddleRailsSubscriptionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :paddle_rails_subscription_items do |t|
      t.references :subscription, foreign_key: { to_table: :paddle_rails_subscriptions }, null: false, index: true
      t.references :subscription_price, foreign_key: { to_table: :paddle_rails_subscription_prices }, null: false, index: true
      t.string :paddle_item_id
      t.integer :quantity, default: 1
      t.string :status
      t.boolean :recurring, default: false

      t.timestamps
    end

    add_index :paddle_rails_subscription_items, [:subscription_id, :subscription_price_id], unique: true, name: "index_subscription_items_on_subscription_and_price"
  end
end

