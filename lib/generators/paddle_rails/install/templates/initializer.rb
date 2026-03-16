# frozen_string_literal: true

PaddleRails.configure do |config|
  # Paddle API credentials
  # Priority: ENV var → Rails credentials → nil
  config.api_key = ENV["PADDLE_API_KEY"] || Rails.application.credentials.dig(:paddle, :api_key)
  config.public_token = ENV["PADDLE_PUBLIC_TOKEN"] || Rails.application.credentials.dig(:paddle, :public_token)
  config.environment = ENV["PADDLE_ENVIRONMENT"] || Rails.application.credentials.dig(:paddle, :environment) || "sandbox"
  config.webhook_secret = ENV["PADDLE_WEBHOOK_SECRET"] || Rails.application.credentials.dig(:paddle, :webhook_secret)

  # How to identify the subscription owner in the billing portal.
  # Defaults to: current_user || warden.authenticate!(scope: :user)
  #
  # config.subscription_owner_authenticator do
  #   current_user || warden.authenticate!(scope: :user)
  # end

  # Where the "Back" link goes in the customer portal sidebar.
  # Defaults to: main_app.root_path
  #
  # config.customer_portal_back_path do
  #   main_app.root_path
  # end
end
