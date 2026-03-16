module PaddleRails
  class ApplicationController < ::ApplicationController
    include SubscriptionOwner

    before_action :ensure_subscription_owner

    private

    def ensure_subscription_owner
      unless subscription_owner
        redirect_to main_app.root_path, alert: "You must be signed in to access this page."
        return
      end

      unless subscription_owner.respond_to?(:subscription?)
        render template: "paddle_rails/shared/configuration_error", status: :internal_server_error, layout: "paddle_rails/application"
        nil
      end
    end
  end
end
