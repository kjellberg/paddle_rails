# frozen_string_literal: true

module PaddleRails
  # Model representing an individual item within a subscription.
  #
  # A subscription can have multiple items (e.g., base plan + addons).
  # Each item links to a specific price and tracks its quantity and status.
  class SubscriptionItem < ApplicationRecord
    self.table_name = "paddle_rails_subscription_items"

    belongs_to :subscription, class_name: "PaddleRails::Subscription"
    belongs_to :subscription_price, class_name: "PaddleRails::SubscriptionPrice"
    alias_method :price, :subscription_price

    delegate :plan, to: :subscription_price

    validates :subscription_id, presence: true
    validates :subscription_price_id, presence: true
    validates :quantity, presence: true, numericality: { greater_than: 0 }
    validates :status, presence: true

    # Returns true if this item is active.
    # @return [Boolean]
    def active?
      status == "active"
    end

    # Returns true if this item is recurring.
    # @return [Boolean]
    def recurring?
      recurring == true
    end
  end
end

