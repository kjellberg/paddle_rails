module PaddleRails
  class Engine < ::Rails::Engine
    isolate_namespace PaddleRails

    initializer "paddle_rails.configuration" do
      Paddle.configure do |config|
        config.environment = ENV.fetch("PADDLE_ENVIRONMENT", "sandbox").to_sym
        config.api_key = ENV.fetch("PADDLE_API_KEY")
      end
    end

    config.to_prepare do
      # Include controller concern in engine's ApplicationController
      PaddleRails::ApplicationController.include(PaddleRails::SubscriptionOwner)

      # Include view helper in engine's ApplicationHelper
      PaddleRails::ApplicationHelper.include(PaddleRails::SubscriptionOwnerHelper)

      # Make helpers available globally
      ActionController::Base.include(PaddleRails::SubscriptionOwner)
      ActionView::Base.include(PaddleRails::SubscriptionOwnerHelper)
    end
  end
end
