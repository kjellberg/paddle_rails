# frozen_string_literal: true

module PaddleRails
  # Model representing a completed payment/transaction from Paddle.
  #
  # Stores payment data parsed from transaction.completed webhooks.
  class Payment < ApplicationRecord
    self.table_name = "paddle_rails_payments"

    belongs_to :subscription, class_name: "PaddleRails::Subscription"
    belongs_to :owner, polymorphic: true

    validates :paddle_transaction_id, presence: true, uniqueness: true
    validates :status, presence: true

    scope :completed, -> { where(status: "completed") }
    scope :recent, -> { order(billed_at: :desc) }

    # Returns the amount in the payment's currency as a decimal.
    # @return [Float]
    def amount_in_currency
      return 0.0 unless total
      total / 100.0
    end

    # Returns a description of the payment based on line items.
    # @return [String]
    def description
      return "Payment" unless details.is_a?(Hash)

      line_items = details["line_items"] || details[:line_items] || []
      return "Payment" if line_items.empty?

      # Get the first line item's product name
      first_item = line_items.first
      product = first_item&.dig("product") || first_item&.dig(:product)
      product_name = product&.dig("name") || product&.dig(:name)

      product_name || "Payment"
    end
  end
end

