# frozen_string_literal: true

module PaddleRails
  # Configuration class for PaddleRails gem settings.
  #
  # @example Configuring PaddleRails
  #   PaddleRails.configure do |config|
  #     config.api_key = "your_api_key"
  #     config.public_token = "your_public_token"
  #     config.subscription_owner_authenticator do
  #       current_user || warden.authenticate!(scope: :user)
  #     end
  #   end
  class Configuration
    # @!attribute subscription_owner_authenticator
    #   @return [Proc] The block used to authenticate the subscription owner.
    #     Defaults to `current_user || warden.authenticate!(scope: :user)`
    # @!attribute customer_portal_back_path
    #   @return [Proc] The block used to generate the back link path shown in
    #     the customer portal sidebar. Evaluated in the controller or view
    #     context and defaults to `main_app.root_path`.
    # @!attribute api_key
    #   @return [String] The Paddle API key. Defaults to ENV["PADDLE_API_KEY"]
    # @!attribute public_token
    #   @return [String] The Paddle public token. Defaults to ENV["PADDLE_PUBLIC_TOKEN"]
    # @!attribute environment
    #   @return [String] The Paddle environment ("sandbox" or "production"). Defaults to ENV["PADDLE_ENVIRONMENT"] or "sandbox"
    # @!attribute webhook_secret
    #   @return [String] The webhook secret key for verifying webhook signatures. Defaults to ENV["PADDLE_WEBHOOK_SECRET"]
    attr_accessor :subscription_owner_authenticator,
                  :customer_portal_back_path,
                  :api_key,
                  :public_token,
                  :environment,
                  :webhook_secret

    # Initialize a new Configuration instance with default values.
    #
    # Sets up default authenticator following Doorkeeper pattern and
    # loads API key and public token from environment variables.
    def initialize
      # Default authenticator following Doorkeeper pattern
      @subscription_owner_authenticator = proc do
        current_user || warden.authenticate!(scope: :user)
      end

      # Default back link in the customer portal sidebar
      @customer_portal_back_path = proc do
        main_app.root_path
      end

      @api_key = ENV["PADDLE_API_KEY"] || Rails.application.credentials.dig(:paddle, :api_key)
      @public_token = ENV["PADDLE_PUBLIC_TOKEN"] || Rails.application.credentials.dig(:paddle, :public_token)
      @environment = ENV["PADDLE_ENVIRONMENT"] || Rails.application.credentials.dig(:paddle, :environment) || "sandbox"
      @webhook_secret = ENV["PADDLE_WEBHOOK_SECRET"] || Rails.application.credentials.dig(:paddle, :webhook_secret)
    end

    # Configure the subscription owner authenticator block.
    #
    # @param block [Proc] The block to use for authenticating subscription owners.
    #   The block is evaluated in the context of the controller or view.
    # @return [Proc] The configured authenticator block
    #
    # @example
    #   config.subscription_owner_authenticator do
    #     current_user
    #   end
    #
    # @example Multi-tenant setup
    #   config.subscription_owner_authenticator do
    #     current_tenant
    #   end
    def subscription_owner_authenticator(&block)
      @subscription_owner_authenticator = block if block_given?
      @subscription_owner_authenticator
    end

    # Configure the customer portal back path block.
    #
    # @param block [Proc] The block to use for generating the back link path.
    #   The block is evaluated in the context of the controller or view.
    # @return [Proc] The configured back path block
    #
    # @example
    #   config.customer_portal_back_path do
    #     main_app.dashboard_path
    #   end
    def customer_portal_back_path(&block)
      @customer_portal_back_path = block if block_given?
      @customer_portal_back_path
    end
  end

  class << self
    # Configure PaddleRails settings.
    #
    # @yield [config] Yields the configuration instance
    # @yieldparam config [Configuration] The configuration instance to modify
    # @return [Configuration] The configuration instance
    #
    # @example
    #   PaddleRails.configure do |config|
    #     config.api_key = "your_api_key"
    #     config.subscription_owner_authenticator do
    #       current_user
    #     end
    #   end
    def configure
      yield(configuration) if block_given?
      configuration
    end

    # Get the current configuration instance.
    #
    # @return [Configuration] The singleton configuration instance
    def configuration
      @configuration ||= Configuration.new
    end
  end
end
