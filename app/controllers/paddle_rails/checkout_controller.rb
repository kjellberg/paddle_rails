# frozen_string_literal: true

module PaddleRails
  class CheckoutController < ApplicationController
    before_action :require_transaction_id, only: [ :show ]

    def show
      # Paddle.js will automatically open the checkout when the transaction ID
      # is passed as a query parameter. No additional logic needed.
    end

    # Creates a transaction to update payment method and redirects to checkout.
    #
    # Uses the Paddle API endpoint:
    # GET /subscriptions/{subscription_id}/update-payment-method-transaction
    #
    # @see https://developer.paddle.com/api-reference/subscriptions/update-payment-method
    def update_payment_method
      subscription = subscription_owner.subscription

      unless subscription
        redirect_to root_path, alert: "No active subscription found."
        return
      end

      begin
        # Call Paddle API to get a transaction for updating payment method
        # This returns a transaction with a checkout URL
        # https://developer.paddle.com/api-reference/subscriptions/update-payment-method
        response = Paddle::Subscription.get_transaction(
          id: subscription.paddle_subscription_id
        )

        checkout_url = response.checkout&.url

        unless checkout_url.present?
          redirect_to root_path, alert: "Unable to create payment update session. Please try again."
          return
        end

        # Redirect to Paddle checkout to update payment method
        redirect_to checkout_url, allow_other_host: true
      rescue Paddle::Error => e
        Rails.logger.error("PaddleRails::CheckoutController: Failed to get payment update transaction: #{e.message}")
        redirect_to root_path, alert: "Failed to update payment method. Please try again."
      end
    end

    def check_status
      transaction_id = params[:transaction_id]

      unless transaction_id.present?
        render json: { status: "error", message: "Transaction ID is required" }, status: :bad_request
        return
      end

      # Try to find subscription locally first by checking webhook events
      # or by querying Paddle transaction
      subscription = find_subscription_by_transaction(transaction_id)

      # If not found locally, proactively sync from Paddle
      unless subscription
        begin
          transaction = Paddle::Transaction.retrieve(id: transaction_id)

          # Extract subscription_id from transaction
          subscription_id = transaction.subscription_id

          if subscription_id.present?
            # Sync the subscription from Paddle
            subscription = SubscriptionSync.sync_from_paddle(subscription_id)
          end
        rescue => e
          Rails.logger.error("PaddleRails::CheckoutController: Error fetching transaction #{transaction_id}: #{e.message}")
          render json: { status: "pending", message: "Transaction not yet processed" }, status: :ok
          return
        end
      end

      # Check if subscription is active
      if subscription&.active?
        render json: {
          status: "active",
          redirect_url: paddle_rails.root_path
        }, status: :ok
      else
        render json: { status: "pending", message: "Subscription is being processed" }, status: :ok
      end
    end

    private

    def require_transaction_id
      unless params[:_ptxn].present?
        redirect_to onboarding_path, alert: "Invalid checkout session. Please try again."
      end
    end

    # Try to find a subscription by transaction ID.
    # This checks webhook events as a fallback since we don't store transaction_id on subscriptions.
    #
    # @param transaction_id [String] The Paddle transaction ID
    # @return [PaddleRails::Subscription, nil]
    def find_subscription_by_transaction(transaction_id)
      # Check webhook events for this transaction
      webhook_event = WebhookEvent.where("payload->>'transaction_id' = ?", transaction_id).first

      if webhook_event
        payload = webhook_event.payload
        subscription_id = payload.dig("subscription_id") || payload.dig("data", "subscription_id")

        if subscription_id
          return Subscription.find_by(paddle_subscription_id: subscription_id)
        end
      end

      nil
    end
  end
end
