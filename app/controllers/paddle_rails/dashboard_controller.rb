module PaddleRails
  class DashboardController < ApplicationController
    before_action :redirect_to_onboarding_if_no_subscription

    def show
      @subscription = SubscriptionPresenter.new(subscription_owner.subscription)
      
      # Load products for change plan widget
      products = Product.active.includes(:prices)
      sorted_products = products.sort_by do |product|
        product.prices.active.minimum(:unit_price) || Float::INFINITY
      end
      @products = sorted_products.each_with_index.map do |product, index|
        ProductPresenter.new(product, index: index)
      end
    end

    private

    def redirect_to_onboarding_if_no_subscription
      return unless subscription_owner

      unless subscription_owner.subscription?
        redirect_to onboarding_path
      end
    end
  end
end
