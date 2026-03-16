# frozen_string_literal: true

module PaddleRails
  # Service for synchronizing Paddle subscription data to the local database.
  #
  # Handles resolving the owner from custom_data and creating/updating the
  # PaddleRails::Subscription record.
  class SubscriptionSync
    # Sync a subscription by fetching it from the Paddle API.
    #
    # @param subscription_id [String] The Paddle subscription ID (sub_...)
    # @return [PaddleRails::Subscription] The synced subscription record
    def self.sync_from_paddle(subscription_id)
      # Use the Paddle gem to retrieve the subscription
      subscription = Paddle::Subscription.retrieve(id: subscription_id)

      # Convert to a hash compatible with our sync logic
      # Note: The Paddle gem returns OpenStruct-like objects, so we need to handle that.
      # Assuming Paddle gem returns an object where attributes are methods.
      # We can probably pass the object directly to sync_from_payload if it responds to hash-like methods
      # or convert it. For safety, let's pass the raw response if possible, or the object.

      # If the gem returns a response object that wraps the data:
      payload = subscription.respond_to?(:attributes) ? subscription.attributes : subscription.to_h

      new(payload).sync
    end

    # Sync a subscription from a webhook or API payload.
    #
    # @param payload [Hash, Object] The subscription data from Paddle
    # @return [PaddleRails::Subscription] The synced subscription record
    def self.sync_from_payload(payload)
      new(payload).sync
    end

    def initialize(payload)
      # Normalize payload to a hash with string keys
      @payload = payload.is_a?(Hash) ? payload.stringify_keys : payload.to_h.stringify_keys
    end

    def sync
      paddle_subscription_id = @payload["id"]
      return nil unless paddle_subscription_id

      # Find existing subscription or initialize new one
      subscription = Subscription.find_or_initialize_by(paddle_subscription_id: paddle_subscription_id)

      # Extract attributes
      status = @payload["status"]

      # Dates
      current_period = @payload["current_billing_period"]
      current_period_end_at = current_period&.dig("ends_at")

      # Scheduled Change
      scheduled_change = @payload["scheduled_change"]
      scheduled_cancelation_at = if scheduled_change&.dig("action") == "cancel"
                                   scheduled_change["effective_at"]
      end

      # Items
      items = @payload["items"] || []

      # Resolve Owner
      owner = resolve_owner

      # If owner is missing for a new subscription, we can't save it properly
      # unless we allow orphans. For now, we log an error if owner is missing.
      if owner.nil? && subscription.new_record?
        Rails.logger.error("PaddleRails::SubscriptionSync: Could not resolve owner for subscription #{paddle_subscription_id}. Custom data: #{@payload['custom_data']}")
        # We might want to create it anyway if we can link it later, but validation requires owner.
        return nil
      end

      # Update attributes
      subscription.status = status
      subscription.current_period_end_at = current_period_end_at
      subscription.scheduled_cancelation_at = scheduled_cancelation_at
      subscription.owner = owner if owner # Only update owner if resolved (don't overwrite with nil)
      subscription.raw_payload = @payload

      subscription.save!

      # Sync items
      sync_items(subscription, items)

      subscription
    end

    private

    def resolve_owner
      custom_data = @payload["custom_data"] || {}
      owner_sgid = custom_data["owner_sgid"]

      return nil unless owner_sgid

      # Use GlobalID to locate the owner
      GlobalID::Locator.locate_signed(owner_sgid, for: "paddle_rails_owner")
    rescue => e
      Rails.logger.error("PaddleRails::SubscriptionSync: Error resolving owner: #{e.message}")
      nil
    end

    # Sync subscription items from the payload.
    #
    # @param subscription [PaddleRails::Subscription] The subscription to sync items for
    # @param items_payload [Array] Array of item hashes from Paddle
    # @return [void]
    def sync_items(subscription, items_payload)
      return unless items_payload.is_a?(Array)

      # Track which price IDs we've seen in this sync
      seen_price_ids = []

      items_payload.each do |item_data|
        price_data = item_data["price"] || item_data.dig("price")
        next unless price_data

        paddle_price_id = price_data["id"]
        next unless paddle_price_id

        # Find the local price record
        price_record = find_price_by_paddle_id(paddle_price_id)
        next unless price_record

        seen_price_ids << price_record.id

        # Find or initialize the subscription item by subscription and price
        subscription_item = subscription.items.find_or_initialize_by(
          price_id: price_record.id
        )

        # Set product reference (through price)
        subscription_item.product = price_record.product

        # Update attributes
        subscription_item.quantity = item_data["quantity"] || 1
        subscription_item.status = item_data["status"]
        subscription_item.recurring = item_data["recurring"] == true

        subscription_item.save!
      end

      # Delete items that are no longer in the payload (full sync)
      subscription.items.where.not(price_id: seen_price_ids).destroy_all
    end

    # Find a Price by its Paddle price ID.
    #
    # @param paddle_price_id [String] The Paddle price ID
    # @return [PaddleRails::Price, nil]
    def find_price_by_paddle_id(paddle_price_id)
      Price.find_by(paddle_price_id: paddle_price_id)
    end

    # Sync payment method from a transaction payload.
    #
    # Called when processing transaction.completed webhooks.
    # Extracts payment method details from the transaction's payments array
    # and updates the associated subscription.
    #
    # @param transaction_payload [Hash] The transaction data from Paddle
    # @return [PaddleRails::Subscription, nil] The updated subscription or nil
    def self.sync_payment_method_from_transaction(transaction_payload)
      payload = transaction_payload.is_a?(Hash) ? transaction_payload.stringify_keys : transaction_payload.to_h.stringify_keys

      subscription_id = payload["subscription_id"]
      return nil unless subscription_id

      subscription = Subscription.find_by(paddle_subscription_id: subscription_id)
      return nil unless subscription

      # Get the first successful payment from the payments array
      payments = payload["payments"] || []
      payment = payments.find { |p| p["status"] == "captured" } || payments.first
      return nil unless payment

      payment_method_id = payment["payment_method_id"]
      method_details = payment["method_details"]

      return nil unless method_details

      # Extract payment method details
      details = extract_payment_details_from_transaction(method_details)

      subscription.payment_method_id = payment_method_id
      subscription.payment_method_type = method_details["type"]
      subscription.payment_method_details = details
      subscription.save!

      subscription
    rescue StandardError => e
      Rails.logger.error("PaddleRails::SubscriptionSync: Error syncing payment method from transaction: #{e.message}")
      nil
    end

    # Extract payment method details from transaction method_details.
    #
    # Handles the nested structure from transaction.completed webhooks:
    # {
    #   "type": "card",
    #   "card": {
    #     "type": "visa",
    #     "last4": "4242",
    #     "expiry_year": 2028,
    #     "expiry_month": 12,
    #     "cardholder_name": "..."
    #   }
    # }
    #
    # @param method_details [Hash] The method_details from payment
    # @return [Hash] Extracted details for storage
    def self.extract_payment_details_from_transaction(method_details)
      return {} unless method_details.is_a?(Hash)

      details = { type: method_details["type"] }

      card_data = method_details["card"]
      if card_data.is_a?(Hash)
        details[:card] = {
          brand: card_data["type"]&.upcase, # In transaction payload, card brand is in "type" field
          last4: card_data["last4"],
          expiry_month: card_data["expiry_month"],
          expiry_year: card_data["expiry_year"],
          cardholder_name: card_data["cardholder_name"]
        }.compact
      end

      details
    end

    # Sync a payment from a transaction.completed webhook payload.
    #
    # Creates or updates a Payment record with transaction data.
    #
    # @param transaction_payload [Hash] The transaction data from Paddle
    # @return [PaddleRails::Payment, nil] The synced payment record or nil
    def self.sync_payment(transaction_payload)
      payload = transaction_payload.is_a?(Hash) ? transaction_payload.stringify_keys : transaction_payload.to_h.stringify_keys

      paddle_transaction_id = payload["id"]
      return nil unless paddle_transaction_id

      subscription_id = payload["subscription_id"]
      return nil unless subscription_id

      subscription = Subscription.find_by(paddle_subscription_id: subscription_id)
      return nil unless subscription

      # Resolve owner from custom_data or use subscription's owner
      owner = resolve_owner_from_payload(payload) || subscription.owner
      return nil unless owner

      # Extract totals from details
      details = payload["details"] || {}
      totals = details["totals"] || {}

      # Find or initialize payment
      payment = PaddleRails::Payment.find_or_initialize_by(paddle_transaction_id: paddle_transaction_id)

      # Update attributes
      payment.subscription = subscription
      payment.owner = owner
      payment.invoice_id = payload["invoice_id"]
      payment.invoice_number = payload["invoice_number"]
      payment.status = payload["status"]
      payment.origin = payload["origin"]
      payment.total = totals["total"]&.to_i || totals[:total]&.to_i
      payment.tax = totals["tax"]&.to_i || totals[:tax]&.to_i
      payment.subtotal = totals["subtotal"]&.to_i || totals[:subtotal]&.to_i
      payment.currency = totals["currency_code"] || totals[:currency_code] || payload["currency_code"]
      payment.billed_at = payload["billed_at"] || payload["billed_at"]
      payment.details = details
      payment.raw_payload = payload

      payment.save!
      payment
    rescue StandardError => e
      Rails.logger.error("PaddleRails::SubscriptionSync: Error syncing payment: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      nil
    end

    # Resolve owner from transaction payload's custom_data.
    #
    # @param payload [Hash] The transaction payload
    # @return [Object, nil] The owner object or nil
    def self.resolve_owner_from_payload(payload)
      custom_data = payload["custom_data"] || {}
      owner_sgid = custom_data["owner_sgid"]

      return nil unless owner_sgid

      GlobalID::Locator.locate_signed(owner_sgid, for: "paddle_rails_owner")
    rescue => e
      Rails.logger.error("PaddleRails::SubscriptionSync: Error resolving owner from payload: #{e.message}")
      nil
    end
  end
end
