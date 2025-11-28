class CreatePaddleRailsSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :paddle_rails_subscriptions do |t|
      t.references :owner, polymorphic: true, null: false, index: true
      t.string :paddle_subscription_id, null: false
      t.string :paddle_price_id
      t.string :status
      t.datetime :current_period_end_at
      t.datetime :trial_ends_at
      t.json :raw_payload
      t.references :subscription_price, foreign_key: { to_table: :paddle_rails_subscription_prices }, index: true

      t.timestamps
    end

    add_index :paddle_rails_subscriptions, :paddle_subscription_id, unique: true
    add_index :paddle_rails_subscriptions, :paddle_price_id
    add_index :paddle_rails_subscriptions, :status
  end
end

