# This migration comes from paddle_rails (originally 20251129222345)
class CreatePaddleRailsPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :paddle_rails_payments do |t|
      t.references :subscription, null: false, foreign_key: { to_table: :paddle_rails_subscriptions }
      t.references :owner, polymorphic: true, null: false
      t.string :paddle_transaction_id, null: false
      t.string :invoice_id
      t.string :invoice_number
      t.string :status, null: false
      t.string :origin  # subscription_recurring, subscription_update, etc.
      t.integer :total  # total in cents (incl. tax)
      t.integer :tax
      t.integer :subtotal
      t.string :currency
      t.datetime :billed_at
      t.json :details  # store line_items and other details
      t.json :raw_payload
      t.timestamps
    end

    add_index :paddle_rails_payments, :paddle_transaction_id, unique: true
    add_index :paddle_rails_payments, [:owner_type, :owner_id]
  end
end
