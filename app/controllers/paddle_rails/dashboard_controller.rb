module PaddleRails
  class DashboardController < ApplicationController
    before_action :redirect_to_onboarding_if_no_subscription

    def show
    end

    private

    def redirect_to_onboarding_if_no_subscription
      return unless subscription_owner

      # Check if subscription_owner has a subscription
      if subscription_owner.respond_to?(:subscription) && subscription_owner.subscription.nil?
        redirect_to onboarding_path
      elsif subscription_owner.respond_to?(:subscribed?) && !subscription_owner.subscribed?
        redirect_to onboarding_path
      end
    end
  end
end
