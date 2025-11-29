# This migration comes from paddle_rails (originally 20251129121336)
class AddPaymentMethodToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :paddle_rails_subscriptions, :payment_method_id, :string
    add_column :paddle_rails_subscriptions, :payment_method_type, :string
    add_column :paddle_rails_subscriptions, :payment_method_details, :json

    add_index :paddle_rails_subscriptions, :payment_method_id
  end
end

