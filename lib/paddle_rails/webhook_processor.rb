# frozen_string_literal: true

module PaddleRails
  # Service class for processing webhook events.
  #
  # Delegates to specific handlers based on event type and emits
  # ActiveSupport::Notifications for host applications to listen to.
  #
  # @example
  #   PaddleRails::WebhookProcessor.process(webhook_event)
  class WebhookProcessor
    # Process a webhook event.
    #
    # @param event [PaddleRails::WebhookEvent] The webhook event to process
    # @return [void]
    def self.process(event)
      new(event).process
    end

    # @param event [PaddleRails::WebhookEvent]
    def initialize(event)
      @event = event
      @payload = event.payload
      @event_type = event.event_type
    end

    # Process the webhook event.
    #
    # Emits an ActiveSupport::Notification with the event type and payload
    # so host applications can subscribe to specific events.
    #
    # @return [void]
    def process
      # Emit notification for host applications to listen to
      # Format: "paddle_rails.{event_type}"
      notification_name = "paddle_rails.#{@event_type}"
      
      ActiveSupport::Notifications.instrument(notification_name) do |payload|
        payload[:webhook_event] = @event
        payload[:event_type] = @event_type
        payload[:raw_payload] = @payload
        
        # Delegate to specific handler if it exists
        handler_method = handler_method_name
        if respond_to?(handler_method, true)
          send(handler_method)
        end
      end
    end

    private

    # Get the handler method name for the event type.
    #
    # Converts "subscription.created" to "handle_subscription_created"
    #
    # @return [String] The handler method name
    def handler_method_name
      "handle_#{@event_type.tr('.', '_')}"
    end

    # Handler for subscription.created events.
    #
    # This is a placeholder - actual subscription creation logic will be
    # implemented in a future update.
    def handle_subscription_created
      # TODO: Implement subscription creation logic
      # Extract owner from custom_data, create/update subscription record, etc.
    end

    # Handler for subscription.updated events.
    def handle_subscription_updated
      # TODO: Implement subscription update logic
    end

    # Handler for subscription.canceled events.
    def handle_subscription_canceled
      # TODO: Implement subscription cancellation logic
    end

    # Handler for transaction.completed events.
    def handle_transaction_completed
      # TODO: Implement transaction completion logic
    end
  end
end

