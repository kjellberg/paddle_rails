# frozen_string_literal: true

module PaddleRails
  class SubscriptionsController < ApplicationController
    def revoke_cancellation
      subscription = subscription_owner.subscription

      unless subscription
        redirect_to root_path, alert: "No active subscription found."
        return
      end

      unless subscription.scheduled_for_cancellation?
        redirect_to root_path, notice: "Subscription is not scheduled for cancellation."
        return
      end

      begin
        # Use Paddle SDK to remove the scheduled change
        Paddle::Subscription.update(
          id: subscription.paddle_subscription_id,
          scheduled_change: nil
        )

        # Update local record immediately
        subscription.update!(scheduled_cancelation_at: nil)

        redirect_to root_path, notice: "Cancellation has been revoked. Your subscription will continue."
      rescue Paddle::Error => e
        Rails.logger.error("PaddleRails::SubscriptionsController: Failed to revoke cancellation: #{e.message}")
        redirect_to root_path, alert: "Failed to revoke cancellation. Please try again."
      end
    end

    def cancel
      subscription = subscription_owner.subscription

      unless subscription&.active?
        redirect_to root_path, alert: "No active subscription found."
        return
      end

      begin
        # Schedule cancellation at end of period
        Paddle::Subscription.cancel(
          id: subscription.paddle_subscription_id,
          effective_from: "next_billing_period"
        )                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   

        # Update local record immediately
        # We assume it's scheduled for next_billing_period, so we use current_period_end_at
        subscription.update!(scheduled_cancelation_at: subscription.current_period_end_at)

        redirect_to root_path, notice: "Subscription scheduled for cancellation on #{subscription.current_period_end_at&.strftime('%B %d, %Y')}."
      rescue Paddle::Error => e
        Rails.logger.error("PaddleRails::SubscriptionsController: Failed to cancel subscription: #{e.message}")
        redirect_to root_path, alert: "Failed to cancel subscription. Please try again."
      end
    end
  end
end
