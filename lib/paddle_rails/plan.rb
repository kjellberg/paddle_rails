# frozen_string_literal: true

module PaddleRails
  # Base class for subscription plan definitions.
  #
  # Host apps create plan classes in `app/plans/` that inherit from this class
  # and use the DSL to attach metadata, features, and quotas to Paddle products.
  #
  # @example Defining a plan
  #   class ProPlan < PaddleRails::Plan
  #     paddle_product_id "pro_01ABC123"
  #     sandbox_paddle_product_id "pro_01SANDBOX456"
  #     title "Pro"
  #     description "For growing teams"
  #     features ["Unlimited projects", "Priority support"]
  #     quota :requests, limit: 100_000
  #   end
  class Plan
    class << self
      # Registry mapping paddle_product_id to plan class.
      # @return [Hash{String => Class}]
      def registry
        @registry ||= {}
      end

      # Look up a plan instance by Paddle product ID.
      # Searches both production and sandbox product IDs.
      # @param id [String]
      # @return [PaddleRails::Plan, nil]
      def for_product_id(id)
        klass = registry[id]
        klass&.instance
      end

      # Return all registered plan instances (deduplicated).
      # @return [Array<PaddleRails::Plan>]
      def all
        registry.values.uniq.map(&:instance)
      end

      # Returns a singleton instance of this plan class.
      # @return [PaddleRails::Plan]
      def instance
        @instance ||= new
      end

      # DSL: set/get the Paddle product ID and register in the registry.
      # @param id [String, nil]
      # @return [String, nil]
      def paddle_product_id(id = nil)
        if id
          @paddle_product_id = id
          PaddleRails::Plan.registry[id] = self
        end
        @paddle_product_id
      end

      # DSL: set/get the sandbox Paddle product ID and register in the registry.
      # Use this when sandbox and production have different product IDs.
      # @param id [String, nil]
      # @return [String, nil]
      def sandbox_paddle_product_id(id = nil)
        if id
          @sandbox_paddle_product_id = id
          PaddleRails::Plan.registry[id] = self
        end
        @sandbox_paddle_product_id
      end

      # DSL: set/get the plan title.
      # @param value [String, nil]
      # @return [String, nil]
      def title(value = nil)
        @title = value if value
        @title
      end

      # DSL: set/get the plan description.
      # @param value [String, nil]
      # @return [String, nil]
      def description(value = nil)
        @description = value if value
        @description
      end

      # DSL: set/get the features list.
      # @param list [Array<String>, nil]
      # @return [Array<String>]
      def features(list = nil)
        @features = list if list
        @features || []
      end

      # DSL: define a named quota.
      # @param name [Symbol]
      # @param limit [Integer]
      def quota(name, limit:)
        quotas[name] = { limit: limit }
      end

      # All defined quotas.
      # @return [Hash{Symbol => Hash}]
      def quotas
        @quotas ||= {}
      end
    end

    # @return [String, nil]
    def paddle_product_id
      self.class.paddle_product_id
    end

    # @return [String, nil]
    def sandbox_paddle_product_id
      self.class.sandbox_paddle_product_id
    end

    # @return [String, nil] an html_safe string
    def title
      self.class.title&.html_safe
    end

    # @return [String, nil] an html_safe string
    def description
      self.class.description&.html_safe
    end

    # @return [Array<String>] array of html_safe strings
    def features
      self.class.features.map(&:html_safe)
    end

    # @return [Hash{Symbol => Hash}]
    def quotas
      self.class.quotas
    end

    # Return the limit for a named quota.
    # @param name [Symbol]
    # @return [Integer, nil]
    def quota(name)
      quotas.dig(name, :limit)
    end

    # Check if a feature string is present.
    # @param name [String]
    # @return [Boolean]
    def has_feature?(name)
      self.class.features.include?(name)
    end

    # Check if current usage is within the quota limit.
    # Returns true if the quota is not defined (unlimited).
    # @param name [Symbol]
    # @param current_usage [Integer]
    # @return [Boolean]
    def within_quota?(name, current_usage:)
      limit = quota(name)
      return true if limit.nil?

      current_usage <= limit
    end

    # Calculate remaining quota.
    # @param name [Symbol]
    # @param current_usage [Integer]
    # @return [Integer, nil] nil if quota is undefined (unlimited)
    def quota_remaining(name, current_usage:)
      limit = quota(name)
      return nil if limit.nil?

      [ limit - current_usage, 0 ].max
    end

    # Calculate percentage of quota used.
    # @param name [Symbol]
    # @param current_usage [Integer]
    # @return [Integer, nil] percentage (0-100+), nil if quota is undefined
    def quota_percent_used(name, current_usage:)
      limit = quota(name)
      return nil if limit.nil?
      return 0 if limit.zero?

      ((current_usage.to_f / limit) * 100).round
    end
  end
end
