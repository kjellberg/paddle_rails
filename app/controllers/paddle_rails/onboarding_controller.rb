module PaddleRails
  class OnboardingController < ApplicationController
    # include PaddleCheckoutErrorHandler

    before_action :redirect_to_dashboard_if_subscribed

    def show
      products = Product.active.includes(:prices)

      # Order products by their lowest active price (cheapest first)
      sorted_products = products.sort_by do |product|
        product.prices.active.minimum(:unit_price) || Float::INFINITY
      end

      @products = sorted_products.each_with_index.map do |product, index|
        ProductPresenter.new(product, index: index)
      end
    end

    def create_checkout
      price = Price.find_by(paddle_price_id: params[:paddle_price_id])
      
      unless price&.active?
        redirect_to onboarding_path, alert: "Invalid price selected."
        return
      end

      redirect_url = PaddleRails::Checkout.url_for(
          owner: subscription_owner,
          paddle_price_id: price.paddle_price_id,
        checkout_url: checkout_url
      )

      if redirect_url.present?
        redirect_to redirect_url, allow_other_host: true
      else
        redirect_to onboarding_path, alert: "Failed to create checkout. Please try again."
      end
    end

    private

    def redirect_to_dashboard_if_subscribed
      return unless subscription_owner

      # Redirect to dashboard if user already has a subscription
      if subscription_owner.respond_to?(:subscription) && subscription_owner.subscription.present?
        redirect_to root_path
      elsif subscription_owner.respond_to?(:subscription?) && subscription_owner.subscription?
        redirect_to root_path
      end
    end
  end
end

