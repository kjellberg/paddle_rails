# frozen_string_literal: true

module PaddleRails
  module Subscribable
    extend ActiveSupport::Concern

    included do
      has_many :paddle_subscriptions, as: :owner, class_name: "PaddleRails::Subscription", dependent: :destroy
    end

    # Returns all subscriptions for the model instance
    # @return [Array]
    def subscriptions
      paddle_subscriptions
    end

    # Returns the current active subscription or nil
    # @return [PaddleRails::Subscription, nil]
    def subscription
      paddle_subscriptions.active.order(created_at: :desc).first
    end

    # Returns true if the model has a current active subscription
    # @return [Boolean]
    def subscription?
      subscription.present?
    end

    # Create a Paddle checkout for this model instance
    #
    # @param paddle_price_id [String] The Paddle Price ID
    # @param custom_data [Hash] Optional custom data to include
    # @param options [Hash] Additional options for Paddle::Transaction.create
    # @return [Paddle::Transaction]
    def create_paddle_checkout(paddle_price_id:, custom_data: {}, **options)
      PaddleRails::Checkout.create(
        owner: self,
        paddle_price_id: paddle_price_id,
        custom_data: custom_data,
        **options
      )
    end
  end
end

