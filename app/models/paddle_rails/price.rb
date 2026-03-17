# frozen_string_literal: true

module PaddleRails
  class Price < ApplicationRecord
    self.table_name = "paddle_rails_prices"
    self.inheritance_column = nil # Disable STI since we use 'type' for Paddle price type

    belongs_to :product, class_name: "PaddleRails::Product"

    validates :paddle_price_id, presence: true, uniqueness: true

    scope :active, -> { joins(:product).where(paddle_rails_products: { status: "active" }).where(status: "active") }
    scope :for_currency, ->(currency) { where(currency: currency) }

    # Whether this price is active.
    #
    # Mirrors the `active` scope but operates on a single record.
    #
    # @return [Boolean]
    def active?
      status == "active" && product&.status == "active"
    end
  end
end
