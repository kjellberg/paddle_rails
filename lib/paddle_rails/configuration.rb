module PaddleRails
  class Configuration
    attr_accessor :subscription_owner_authenticator, :api_key, :public_token

    def initialize
      # Default authenticator following Doorkeeper pattern
      @subscription_owner_authenticator = proc do
        current_user || warden.authenticate!(scope: :user)
      end
      @api_key = ENV.fetch("PADDLE_API_KEY")
      @public_token = ENV.fetch("PADDLE_PUBLIC_TOKEN")
    end

    def subscription_owner_authenticator(&block)
      @subscription_owner_authenticator = block if block_given?
      @subscription_owner_authenticator
    end
  end

  class << self
    def configure
      yield(configuration) if block_given?
      configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end
end

