module PaddleRails
  class DashboardController < ApplicationController
    before_action :redirect_to_onboarding_if_no_subscription

    def show
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
