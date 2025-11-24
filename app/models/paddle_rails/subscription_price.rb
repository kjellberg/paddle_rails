module PaddleRails
  class SubscriptionPrice < ApplicationRecord
    self.table_name = "paddle_rails_subscription_prices"
    self.inheritance_column = nil # Disable STI since we use 'type' for Paddle price type

    belongs_to :subscription_plan, class_name: "PaddleRails::SubscriptionPlan"

    validates :paddle_price_id, presence: true, uniqueness: true

    scope :active, -> { joins(:subscription_plan).where(paddle_rails_subscription_plans: { status: "active" }).where(status: "active") }
    scope :for_currency, ->(currency) { where(currency: currency) }
  end
end
