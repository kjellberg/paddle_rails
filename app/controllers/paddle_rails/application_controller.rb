module PaddleRails
  class ApplicationController < ::ApplicationController
    include SubscriptionOwner

    before_action :ensure_subscription_owner

    private

    def ensure_subscription_owner
      return if subscription_owner

      redirect_to main_app.root_path, alert: "You must be signed in to access this page."
    end
  end
end
