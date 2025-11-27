# frozen_string_literal: true

module PaddleRails
  module Subscribable
    extend ActiveSupport::Concern

    # Returns all subscriptions for the model instance
    # @return [Array] Empty array for now (will be association later)
    def subscriptions
      []
    end

    # Returns the current subscription or nil
    # @return [nil] nil for now (will return subscription later)
    def subscription
      nil
    end

    # Returns true if the model has a current subscription
    # @return [Boolean] false for now
    def subscription?
      false
    end
  end
end

