# frozen_string_literal: true

module PaddleRails
  # Presenter for subscription products on the onboarding page.
  #
  # Wraps a {SubscriptionProduct} and its active {SubscriptionPrice} records
  # and exposes formatted data for the onboarding view so the template
  # can stay mostly declarative and free from business logic.
  #
  # @example Building presenters in the controller
  #   products = SubscriptionProduct.active.includes(:prices)
  #   @products = products.each_with_index.map do |product, index|
  #     PaddleRails::SubscriptionProductPresenter.new(product, index: index)
  #   end
  #
  # @example Using presenter methods in the view
  #   <% @products.each do |product| %>
  #     <%= product.name %>
  #     <%= product.primary_label %>  <!-- e.g. "29 EUR / month" -->
  #   <% end %>
  class SubscriptionProductPresenter
    attr_reader :product, :index

    # Initialize a new presenter.
    #
    # @param product [PaddleRails::SubscriptionProduct] the product being presented
    # @param index [Integer] zero-based index of the product in the list
    # @param default_currency [String] fallback currency code, defaults to "EUR"
    def initialize(product, index: 0, default_currency: "EUR")
      @product = product
      @index = index
      @default_currency = default_currency
    end

    # Display name for the product.
    #
    # Falls back to `"Product #{index + 1}"` when the record has no name.
    #
    # @return [String]
    def name
      product.name.presence || "Product #{index + 1}"
    end

    # Description text for the product.
    #
    # @return [String, nil]
    def description
      product.description
    end

    # All active prices for the product, ordered by unit price.
    #
    # @return [ActiveRecord::Relation<PaddleRails::SubscriptionPrice>]
    def prices
      @prices ||= product.prices.active.order(:unit_price)
    end

    # Whether the product has any active prices.
    #
    # @return [Boolean]
    def any_prices?
      prices.any?
    end

    # Whether the product has more than one active price.
    #
    # @return [Boolean]
    def multiple_prices?
      prices.many?
    end

    # The primary price used for the default selection.
    #
    # @return [PaddleRails::SubscriptionPrice, nil]
    def primary_price
      prices.first
    end

    # The formatted primary amount, converted from minor units.
    #
    # @return [Integer] whole amount (e.g. 29 for 29.00)
    def primary_amount
      amount_for(primary_price)
    end

    # The currency code for the primary price.
    #
    # @return [String] e.g. "EUR"
    def primary_currency
      currency_for(primary_price)
    end

    # The human-readable billing interval for the primary price.
    #
    # @return [String] e.g. "month", "12 months", or "one-time"
    def primary_billing
      billing_for(primary_price)
    end

    # Full label for the primary price.
    #
    # @return [String] e.g. "29 EUR / month"
    def primary_label
      label_for(primary_price)
    end

    # Paddle price ID of the primary price.
    #
    # @return [String, nil]
    def primary_price_id
      primary_price&.paddle_price_id
    end

    # Trial days for the primary price, if any.
    #
    # @return [Integer, nil]
    def trial_days
      primary_price&.trial_days
    end

    # Returns an array of [paddle_price_id, label] pairs
    # for all active prices on this product.
    #
    # @return [Array<Array(String, String)>]
    def price_options
      prices.map { |price| [price.paddle_price_id, label_for(price)] }
    end

    private

    # Convert a price's unit_price (stored in minor units) to an integer amount.
    #
    # @param price [PaddleRails::SubscriptionPrice, nil]
    # @return [Integer]
    def amount_for(price)
      return 0 unless price&.unit_price

      (price.unit_price / 100.0).to_i
    end

    # Resolve a price's currency or fall back to the default.
    #
    # @param price [PaddleRails::SubscriptionPrice, nil]
    # @return [String]
    def currency_for(price)
      (price&.currency || @default_currency).upcase
    end

    # Build a human-readable billing interval from Paddle data.
    #
    # @param price [PaddleRails::SubscriptionPrice, nil]
    # @return [String]
    def billing_for(price)
      return "one-time" unless price&.billing_interval.present?

      interval = price.billing_interval.to_s.downcase
      count = (price.billing_interval_count || 1).to_i

      case interval
      when "month"
        count == 1 ? "month" : "#{count} months"
      when "year"
        count == 1 ? "year" : "#{count} years"
      else
        price.billing_interval
      end
    end

    # Build a full label for a price.
    #
    # @param price [PaddleRails::SubscriptionPrice, nil]
    # @return [String]
    def label_for(price)
      "#{amount_for(price)} #{currency_for(price)} / #{billing_for(price)}"
    end
  end
end

