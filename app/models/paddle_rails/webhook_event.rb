# frozen_string_literal: true

module PaddleRails
  # Model for storing incoming webhook events from Paddle.
  #
  # Webhooks are stored with their raw payload and processed asynchronously
  # via background jobs to ensure reliability and allow for replayability.
  #
  # @example
  #   event = PaddleRails::WebhookEvent.create!(
  #     external_id: "evt_123",
  #     event_type: "subscription.created",
  #     payload: { ... },
  #     status: "pending"
  #   )
  class WebhookEvent < ApplicationRecord
    self.table_name = "paddle_rails_webhook_events"

    # Status values
    PENDING = "pending"
    PROCESSING = "processing"
    PROCESSED = "processed"
    FAILED = "failed"

    validates :external_id, presence: true, uniqueness: true
    validates :event_type, presence: true
    validates :payload, presence: true
    validates :status, presence: true, inclusion: { in: [PENDING, PROCESSING, PROCESSED, FAILED] }

    scope :pending, -> { where(status: PENDING) }
    scope :processing, -> { where(status: PROCESSING) }
    scope :processed, -> { where(status: PROCESSED) }
    scope :failed, -> { where(status: FAILED) }

    # Mark the event as processing
    def mark_as_processing!
      update!(status: PROCESSING)
    end

    # Mark the event as processed
    def mark_as_processed!
      update!(status: PROCESSED, processed_at: Time.current)
    end

    # Mark the event as failed with an error message
    def mark_as_failed!(error_message)
      update!(status: FAILED, processing_errors: error_message)
    end
  end
end

