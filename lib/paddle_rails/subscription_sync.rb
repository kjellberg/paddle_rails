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
          subscription_price_id: price_record.id
        )

        # Set product reference (through price)
        subscription_item.subscription_product = price_record.subscription_product

        # Update attributes
        subscription_item.quantity = item_data["quantity"] || 1
        subscription_item.status = item_data["status"]
        subscription_item.recurring = item_data["recurring"] == true

        subscription_item.save!
      end

      # Delete items that are no longer in the payload (full sync)
      subscription.items.where.not(subscription_price_id: seen_price_ids).destroy_all
    end

    # Find a SubscriptionPrice by its Paddle price ID.
    #
    # @param paddle_price_id [String] The Paddle price ID
    # @return [PaddleRails::SubscriptionPrice, nil]
    def find_price_by_paddle_id(paddle_price_id)
      SubscriptionPrice.find_by(paddle_price_id: paddle_price_id)
    end
  end
end

