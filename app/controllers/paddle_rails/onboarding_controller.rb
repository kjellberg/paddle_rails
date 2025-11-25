module PaddleRails
  class OnboardingController < ApplicationController
    before_action :redirect_to_dashboard_if_subscribed

    def show
      plans = SubscriptionPlan.active.includes(:prices)

      # Order plans by their lowest active price (cheapest first)
      @plans = plans.sort_by do |plan|
        plan.prices.active.minimum(:unit_price) || Float::INFINITY
      end
    end

    def create_checkout
      price = SubscriptionPrice.find_by(paddle_price_id: params[:paddle_price_id])
      
      unless price&.active?
        redirect_to onboarding_path, alert: "Invalid price selected."
        return
      end

      begin
        checkout = subscription_owner.create_paddle_checkout(
          paddle_price_id: price.paddle_price_id
        )

        # Paddle::Transaction (OpenStruct) returns checkout URL in checkout_url or url attribute
        checkout_url = checkout.checkout_url if checkout.respond_to?(:checkout_url)
        checkout_url ||= checkout.url if checkout.respond_to?(:url)

        if checkout_url.present?
          redirect_to checkout_url, allow_other_host: true
        else
          redirect_to onboarding_path, alert: "Failed to create checkout. Please try again."
        end
      rescue => e
        Rails.logger.error("PaddleRails::OnboardingController: Error creating checkout: #{e.message}")
        redirect_to onboarding_path, alert: "Failed to create checkout. Please try again."
      end
    end

    private

    def redirect_to_dashboard_if_subscribed
      return unless subscription_owner

      # Redirect to dashboard if user already has a subscription
      if subscription_owner.respond_to?(:subscription) && subscription_owner.subscription.present?
        redirect_to root_path
      elsif subscription_owner.respond_to?(:subscribed?) && subscription_owner.subscribed?
        redirect_to root_path
      end
    end
  end
end

