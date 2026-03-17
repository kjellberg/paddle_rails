# frozen_string_literal: true

# PaddleRails is a zero-hassle Paddle subscription integration for Rails
# using custom_data-based identity.
#
# @example Basic usage
#   # In config/initializers/paddle_rails.rb
#   PaddleRails.configure do |config|
#     config.api_key = ENV["PADDLE_API_KEY"]
#     config.subscription_owner_authenticator do
#       current_user || warden.authenticate!(scope: :user)
#     end
#   end
#
# @example Making a model subscribable
#   class User < ApplicationRecord
#     include PaddleRails::Subscribable
#   end
#
# @see https://github.com/kjellberg/paddle_rails
module PaddleRails
  # Base error class for all PaddleRails errors
  class Error < StandardError; end

  # Raised when configuration is missing or invalid
  class ConfigurationError < Error; end

  # Raised when webhook signature verification fails
  class WebhookVerificationError < Error; end

  # Raised when subscription sync encounters an unrecoverable problem
  class SyncError < Error; end

  def self.pricing_plans_available?
    defined?(::PricingPlans) && ::PricingPlans.respond_to?(:plans)
  end
end

require "paddle"
require "paddle_rails/version"
require "paddle_rails/engine"
require "paddle_rails/configuration"
require "paddle_rails/product_sync"
require "paddle_rails/checkout"
require "paddle_rails/webhook_verifier"
require "paddle_rails/webhook_processor"
require "paddle_rails/subscription_sync"
require "paddle_rails/plan"
