# frozen_string_literal: true

module PaddleRails
  # Presenter that bridges a PricingPlans::Plan to Paddle price data.
  #
  # Wraps a {PricingPlans::Plan} and resolves associated Paddle {Price}
  # records via the plan's +paddle_rails_price+ configuration. Exposes the
  # same view interface the billing templates need so they can stay
  # declarative.
  #
  # @example Building presenters in a controller
  #   @plans = ::PricingPlans.plans.map { |plan|
  #     PricingPlanPresenter.new(plan, current_plan: current_plan)
  #   }
  class PricingPlanPresenter
    attr_reader :pricing_plan

    # @param pricing_plan [PricingPlans::Plan]
    # @param current_plan [PricingPlans::Plan, nil] the user's current plan (for comparison)
    # @param default_currency [String] fallback currency code
    def initialize(pricing_plan, current_plan: nil, default_currency: "EUR")
      @pricing_plan = pricing_plan
      @current_plan = current_plan
      @default_currency = default_currency
    end

    # ── Metadata from pricing_plans ──────────────────────────────

    def name
      pricing_plan.name
    end

    def description
      pricing_plan.description
    end

    def plan_features
      pricing_plan.bullets || []
    end

    def highlighted?
      pricing_plan.highlighted?
    end

    # ── Plan comparison ──────────────────────────────────────────

    def current?
      return false unless @current_plan
      pricing_plan.current_for?(@current_plan)
    end

    def upgrade?
      return false unless @current_plan
      pricing_plan.upgrade_from?(@current_plan)
    end

    def downgrade?
      return false unless @current_plan
      pricing_plan.downgrade_from?(@current_plan)
    end

    # ── Paddle billing data ──────────────────────────────────────

    def prices
      paddle_prices
    end

    def any_prices?
      paddle_prices.any?
    end

    def multiple_prices?
      paddle_prices.many?
    end

    def primary_price
      paddle_prices.first
    end

    def primary_amount
      amount_for(primary_price)
    end

    def primary_currency
      currency_for(primary_price)
    end

    def primary_billing
      billing_for(primary_price)
    end

    def primary_label
      label_for(primary_price)
    end

    def primary_price_id
      primary_price&.paddle_price_id
    end

    def trial_days
      primary_price&.trial_days
    end

    def price_options
      paddle_prices.map { |price| [price.paddle_price_id, label_for(price)] }
    end

    # Product resolved from first price — needed for form IDs.
    def product
      primary_price&.product
    end

    private

    def paddle_prices
      @paddle_prices ||= begin
        pp = pricing_plan.paddle_rails_price
        return PaddleRails::Price.none unless pp
        price_ids = pp.is_a?(Hash) ? pp.values.compact : [pp].compact
        PaddleRails::Price.where(paddle_price_id: price_ids).active.order(:unit_price)
      end
    end

    def amount_for(price)
      return 0 unless price&.unit_price
      (price.unit_price / 100.0).to_i
    end

    def currency_for(price)
      (price&.currency || @default_currency).upcase
    end

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

    def label_for(price)
      "#{amount_for(price)} #{currency_for(price)} / #{billing_for(price)}"
    end
  end
end
