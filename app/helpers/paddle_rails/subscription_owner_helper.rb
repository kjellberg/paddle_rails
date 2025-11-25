module PaddleRails
  module SubscriptionOwnerHelper
    def subscription_owner
      authenticator = PaddleRails.configuration.subscription_owner_authenticator
      return nil unless authenticator

      instance_eval(&authenticator)
    rescue StandardError => e
      Rails.logger.error("PaddleRails::SubscriptionOwnerHelper: Error authenticating subscription owner: #{e.message}")
      nil
    end
  end
end

