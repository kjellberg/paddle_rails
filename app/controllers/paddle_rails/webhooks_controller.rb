# frozen_string_literal: true

module PaddleRails
  # Controller for receiving webhook events from Paddle.
  #
  # This controller:
  # - Verifies webhook signatures
  # - Stores raw events in the database
  # - Enqueues background jobs for processing
  #
  # Webhooks are processed asynchronously to ensure fast response times
  # and allow for retry logic.
  class WebhooksController < ActionController::API
    # Receive and process a webhook event from Paddle.
    #
    # POST /paddle_rails/webhooks
    def create
      # Get raw body (must not be transformed for signature verification)
      raw_body = request.raw_post
      signature_header = request.headers["Paddle-Signature"]

      # Verify signature
      unless verify_signature(raw_body, signature_header)
        Rails.logger.error("PaddleRails::WebhooksController: Invalid webhook signature")
        head :unauthorized
        return
      end

      # Parse payload
      payload = JSON.parse(raw_body)
      external_id = payload["event_id"]
      event_type = payload["event_type"]

      # Check if we've already processed this event (idempotency)
      existing_event = WebhookEvent.find_by(external_id: external_id)
      if existing_event
        Rails.logger.info("PaddleRails::WebhooksController: Webhook #{external_id} already processed, skipping")
        head :ok
        return
      end

      # Create webhook event record
      webhook_event = WebhookEvent.create!(
        external_id: external_id,
        event_type: event_type,
        payload: payload,
        status: WebhookEvent::PENDING
      )

      # Enqueue background job for processing
      ProcessWebhookJob.perform_later(webhook_event.id)

      head :ok
    rescue JSON::ParserError => e
      Rails.logger.error("PaddleRails::WebhooksController: Invalid JSON payload: #{e.message}")
      head :bad_request
    rescue StandardError => e
      Rails.logger.error("PaddleRails::WebhooksController: Error processing webhook: #{e.message}\n#{e.backtrace.join("\n")}")
      head :internal_server_error
    end

    private

    # Verify the webhook signature.
    #
    # @param raw_body [String] The raw request body
    # @param signature_header [String] The Paddle-Signature header value
    # @return [Boolean] true if signature is valid
    def verify_signature(raw_body, signature_header)
      secret_key = PaddleRails.configuration.webhook_secret
      return false if secret_key.blank?

      verifier = WebhookVerifier.new(secret_key)
      verifier.verify(raw_body, signature_header)
    end
  end
end

