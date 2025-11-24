# This migration comes from paddle_rails (originally 20251124180624)
class CreatePaddleRailsSubscriptionPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :paddle_rails_subscription_plans do |t|
      t.string :paddle_product_id, null: false
      t.string :name
      t.text :description
      t.string :status
      t.string :type
      t.string :tax_category
      t.string :image_url
      t.json :custom_data

      t.timestamps
    end

    add_index :paddle_rails_subscription_plans, :paddle_product_id, unique: true
  end
end
