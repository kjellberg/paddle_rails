module PaddleRails
  class SubscriptionPrice < ApplicationRecord
    self.table_name = "paddle_rails_subscription_prices"
    self.inheritance_column = nil # Disable STI since we use 'type' for Paddle price type

    belongs_to :subscription_product, class_name: "PaddleRails::SubscriptionProduct"

    validates :paddle_price_id, presence: true, uniqueness: true

    scope :active, -> { joins(:subscription_product).where(paddle_rails_subscription_products: { status: "active" }).where(status: "active") }
    scope :for_currency, ->(currency) { where(currency: currency) }

    # Whether this price is active.
    #
    # Mirrors the `active` scope but operates on a single record.
    #
    # @return [Boolean]
    def active?
      status == "active"
    end
  end
end
