# frozen_string_literal: true

module PaddleRails
  # Background job for processing webhook events asynchronously.
  #
  # This job finds the webhook event, marks it as processing, calls the
  # WebhookProcessor to handle the event, and updates the status accordingly.
  #
  # @example
  #   PaddleRails::ProcessWebhookJob.perform_later(webhook_event.id)
  class ProcessWebhookJob < ApplicationJob
    queue_as :default

    # Process a webhook event.
    #
    # @param event_id [Integer] The ID of the WebhookEvent to process
    def perform(event_id)
      event = WebhookEvent.find_by(id: event_id)
      unless event
        Rails.logger.error("PaddleRails::ProcessWebhookJob: WebhookEvent #{event_id} not found")
        return
      end

      event.mark_as_processing!

      begin
        WebhookProcessor.process(event)
        event.mark_as_processed!
      rescue StandardError => e
        error_message = "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
        event.mark_as_failed!(error_message)
        Rails.logger.error("PaddleRails::ProcessWebhookJob: Failed to process webhook #{event_id}: #{error_message}")
        raise # Re-raise to trigger ActiveJob retry mechanism
      end
    end
  end
end

