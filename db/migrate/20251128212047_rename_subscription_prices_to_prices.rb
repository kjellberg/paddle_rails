class RenameSubscriptionPricesToPrices < ActiveRecord::Migration[8.1]
  def change
    rename_table :paddle_rails_subscription_prices, :paddle_rails_prices
  end
end

