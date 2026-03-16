# frozen_string_literal: true

require "test_helper"

module PaddleRails
  class PricingPlanPresenterTest < ActiveSupport::TestCase
    setup do
      @product = Product.create!(
        paddle_product_id: "pro_test_product",
        name: "Test Product",
        status: "active"
      )

      @price_monthly = Price.create!(
        paddle_price_id: "pri_monthly_123",
        product: @product,
        unit_price: 2900,
        currency: "EUR",
        billing_interval: "month",
        billing_interval_count: 1,
        status: "active"
      )

      @price_yearly = Price.create!(
        paddle_price_id: "pri_yearly_456",
        product: @product,
        unit_price: 29000,
        currency: "EUR",
        billing_interval: "year",
        billing_interval_count: 1,
        status: "active"
      )
    end

    teardown do
      Price.delete_all
      Product.delete_all
    end

    # ── Metadata delegation ──────────────────────────────────────

    test "name delegates to pricing plan" do
      plan = build_pricing_plan(name: "Pro Plan")
      presenter = PricingPlanPresenter.new(plan)

      assert_equal "Pro Plan", presenter.name
    end

    test "description delegates to pricing plan" do
      plan = build_pricing_plan(description: "For growing teams")
      presenter = PricingPlanPresenter.new(plan)

      assert_equal "For growing teams", presenter.description
    end

    test "plan_features returns bullets from pricing plan" do
      plan = build_pricing_plan(bullets: ["Feature A", "Feature B"])
      presenter = PricingPlanPresenter.new(plan)

      assert_equal ["Feature A", "Feature B"], presenter.plan_features
    end

    test "plan_features returns empty array when bullets is nil" do
      plan = build_pricing_plan(bullets: nil)
      presenter = PricingPlanPresenter.new(plan)

      assert_equal [], presenter.plan_features
    end

    test "highlighted? delegates to pricing plan" do
      plan = build_pricing_plan(highlighted: true)
      presenter = PricingPlanPresenter.new(plan)

      assert presenter.highlighted?
    end

    # ── Comparison delegation ────────────────────────────────────

    test "current? returns false without current_plan" do
      plan = build_pricing_plan
      presenter = PricingPlanPresenter.new(plan)

      assert_not presenter.current?
    end

    test "current? delegates to pricing_plan.current_for?" do
      current = build_pricing_plan(key: :basic)
      plan = build_pricing_plan(key: :basic, current_for: true)
      presenter = PricingPlanPresenter.new(plan, current_plan: current)

      assert presenter.current?
    end

    test "upgrade? delegates to pricing_plan.upgrade_from?" do
      current = build_pricing_plan(key: :basic)
      plan = build_pricing_plan(key: :pro, upgrade_from: true)
      presenter = PricingPlanPresenter.new(plan, current_plan: current)

      assert presenter.upgrade?
    end

    test "downgrade? delegates to pricing_plan.downgrade_from?" do
      current = build_pricing_plan(key: :pro)
      plan = build_pricing_plan(key: :basic, downgrade_from: true)
      presenter = PricingPlanPresenter.new(plan, current_plan: current)

      assert presenter.downgrade?
    end

    # ── Paddle price resolution ──────────────────────────────────

    test "resolves prices from paddle_rails_price hash" do
      plan = build_pricing_plan(
        paddle_rails_price: { month: "pri_monthly_123", year: "pri_yearly_456" }
      )
      presenter = PricingPlanPresenter.new(plan)

      assert_equal 2, presenter.prices.count
      assert presenter.any_prices?
      assert presenter.multiple_prices?
    end

    test "resolves prices from paddle_rails_price string" do
      plan = build_pricing_plan(paddle_rails_price: "pri_monthly_123")
      presenter = PricingPlanPresenter.new(plan)

      assert_equal 1, presenter.prices.count
      assert presenter.any_prices?
      assert_not presenter.multiple_prices?
    end

    test "any_prices? returns false when no matching Paddle prices exist" do
      plan = build_pricing_plan(paddle_rails_price: "pri_nonexistent_999")
      presenter = PricingPlanPresenter.new(plan)

      assert_not presenter.any_prices?
    end

    test "any_prices? returns false when paddle_rails_price is nil" do
      plan = build_pricing_plan(paddle_rails_price: nil)
      presenter = PricingPlanPresenter.new(plan)

      assert_not presenter.any_prices?
    end

    # ── Price formatting ─────────────────────────────────────────

    test "primary_amount converts from minor units" do
      plan = build_pricing_plan(paddle_rails_price: "pri_monthly_123")
      presenter = PricingPlanPresenter.new(plan)

      assert_equal 29, presenter.primary_amount
    end

    test "primary_currency returns uppercase currency" do
      plan = build_pricing_plan(paddle_rails_price: "pri_monthly_123")
      presenter = PricingPlanPresenter.new(plan)

      assert_equal "EUR", presenter.primary_currency
    end

    test "primary_currency falls back to default when no prices" do
      plan = build_pricing_plan(paddle_rails_price: nil)
      presenter = PricingPlanPresenter.new(plan, default_currency: "USD")

      assert_equal "USD", presenter.primary_currency
    end

    test "primary_billing returns interval string" do
      plan = build_pricing_plan(paddle_rails_price: "pri_monthly_123")
      presenter = PricingPlanPresenter.new(plan)

      assert_equal "month", presenter.primary_billing
    end

    test "primary_label combines amount, currency, and billing" do
      plan = build_pricing_plan(paddle_rails_price: "pri_monthly_123")
      presenter = PricingPlanPresenter.new(plan)

      assert_equal "29 EUR / month", presenter.primary_label
    end

    test "primary_price_id returns paddle price id" do
      plan = build_pricing_plan(paddle_rails_price: "pri_monthly_123")
      presenter = PricingPlanPresenter.new(plan)

      assert_equal "pri_monthly_123", presenter.primary_price_id
    end

    test "price_options returns array of [price_id, label] pairs" do
      plan = build_pricing_plan(
        paddle_rails_price: { month: "pri_monthly_123", year: "pri_yearly_456" }
      )
      presenter = PricingPlanPresenter.new(plan)

      options = presenter.price_options
      assert_equal 2, options.size
      assert_equal "pri_monthly_123", options.first.first
      assert_includes options.first.last, "month"
    end

    test "product resolves from primary price" do
      plan = build_pricing_plan(paddle_rails_price: "pri_monthly_123")
      presenter = PricingPlanPresenter.new(plan)

      assert_equal @product, presenter.product
    end

    private

    # Builds a simple stub that quacks like PricingPlans::Plan
    def build_pricing_plan(
      key: :pro,
      name: "Pro",
      description: nil,
      bullets: [],
      highlighted: false,
      paddle_rails_price: nil,
      current_for: false,
      upgrade_from: false,
      downgrade_from: false
    )
      stub = Object.new

      stub.define_singleton_method(:key) { key }
      stub.define_singleton_method(:name) { name }
      stub.define_singleton_method(:description) { description }
      stub.define_singleton_method(:bullets) { bullets }
      stub.define_singleton_method(:highlighted?) { highlighted }
      stub.define_singleton_method(:paddle_rails_price) { paddle_rails_price }
      stub.define_singleton_method(:current_for?) { |_| current_for }
      stub.define_singleton_method(:upgrade_from?) { |_| upgrade_from }
      stub.define_singleton_method(:downgrade_from?) { |_| downgrade_from }

      stub
    end
  end
end
