# frozen_string_literal: true

module PaddleRails
  # Rails engine for PaddleRails gem.
  #
  # Handles configuration of the Paddle client and makes subscription
  # owner helpers available globally in controllers and views.
  #
  # @see PaddleRails::Configuration
  class Engine < ::Rails::Engine
    isolate_namespace PaddleRails

    # Configure the Paddle client with API key from configuration.
    #
    # Sets up the Paddle gem with environment and API key from
    # PaddleRails configuration, falling back to environment variables.
    initializer "paddle_rails.configuration" do
      if PaddleRails.configuration.api_key.present?
        Paddle.configure do |config|
          config.environment = PaddleRails.configuration.environment.to_sym
          config.api_key = PaddleRails.configuration.api_key
        end
      end
    end

    # Add webhook route to main application
    initializer "paddle_rails.routes" do |app|
      app.routes.prepend do
        post "/paddle_rails/webhooks", to: "paddle_rails/webhooks#create", as: :paddle_rails_webhooks
      end
    end

    # Eager-load plan classes from the host app's app/plans/ directory.
    initializer "paddle_rails.eager_load_plans" do
      config.to_prepare do
        PaddleRails::Plan.registry.clear
        plan_path = Rails.root.join("app", "plans")
        if plan_path.exist?
          Dir[plan_path.join("**", "*.rb")].sort.each { |f| require_dependency f }
        end
      end
    end

    # Prepare helpers for inclusion in controllers and views.
    #
    # Makes {PaddleRails::SubscriptionOwner} and {PaddleRails::SubscriptionOwnerHelper}
    # available both within the engine namespace and globally in all controllers
    # and views.
    config.to_prepare do
      # Include controller concern in engine's ApplicationController
      PaddleRails::ApplicationController.include(PaddleRails::SubscriptionOwner)

      # Include view helper in engine's ApplicationHelper
      PaddleRails::ApplicationHelper.include(PaddleRails::SubscriptionOwnerHelper)

      # Make helpers available globally
      ActionController::Base.include(PaddleRails::SubscriptionOwner)
      ActionView::Base.include(PaddleRails::SubscriptionOwnerHelper)
      ActionView::Base.include(PaddleRails::ApplicationHelper)
    end
  end
end
