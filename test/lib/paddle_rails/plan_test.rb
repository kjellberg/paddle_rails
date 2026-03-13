# frozen_string_literal: true

require "test_helper"

module PaddleRails
  class PlanTest < ActiveSupport::TestCase
    class TestFreePlan < PaddleRails::Plan
      paddle_product_id "free_01TEST"
      title "Free"
      description "Get started for free"
      features [ "Basic support", "1 project" ]
    end

    class TestProPlan < PaddleRails::Plan
      paddle_product_id "pro_01TEST"
      sandbox_paddle_product_id "pro_01TEST_SANDBOX"
      title "Pro"
      description "For growing teams &mdash; <strong>unlimited</strong> projects"
      features [ "<strong>50,000</strong> requests per month", "Priority support", "Custom domains" ]
      quota :requests, limit: 50_000
      quota :storage_mb, limit: 10_000
      quota :team_members, limit: 25
    end

    # --- Registration ---

    test "paddle_product_id registers plan in registry" do
      assert_equal TestProPlan, PaddleRails::Plan.registry["pro_01TEST"]
      assert_equal TestFreePlan, PaddleRails::Plan.registry["free_01TEST"]
    end

    # --- Lookup ---

    test "for_product_id returns plan instance" do
      plan = PaddleRails::Plan.for_product_id("pro_01TEST")
      assert_instance_of TestProPlan, plan
    end

    test "for_product_id returns nil for unknown ID" do
      assert_nil PaddleRails::Plan.for_product_id("unknown_01NOPE")
    end

    test "for_product_id returns singleton instance" do
      plan1 = PaddleRails::Plan.for_product_id("pro_01TEST")
      plan2 = PaddleRails::Plan.for_product_id("pro_01TEST")
      assert_same plan1, plan2
    end

    # --- All ---

    test "all returns all registered plan instances" do
      plans = PaddleRails::Plan.all
      assert_includes plans.map(&:class), TestFreePlan
      assert_includes plans.map(&:class), TestProPlan
    end

    # --- Instance getters ---

    test "title returns html_safe string" do
      plan = TestProPlan.instance
      assert_equal "Pro", plan.title
      assert_predicate plan.title, :html_safe?
    end

    test "description returns html_safe string" do
      plan = TestProPlan.instance
      assert_includes plan.description, "&mdash;"
      assert_predicate plan.description, :html_safe?
    end

    test "features returns array of html_safe strings" do
      plan = TestProPlan.instance
      assert_equal 3, plan.features.length
      plan.features.each do |f|
        assert_predicate f, :html_safe?
      end
    end

    test "paddle_product_id returns the ID" do
      plan = TestProPlan.instance
      assert_equal "pro_01TEST", plan.paddle_product_id
    end

    # --- Sandbox product ID ---

    test "sandbox_paddle_product_id registers in registry" do
      assert_equal TestProPlan, PaddleRails::Plan.registry["pro_01TEST_SANDBOX"]
    end

    test "for_product_id finds plan by sandbox ID" do
      plan = PaddleRails::Plan.for_product_id("pro_01TEST_SANDBOX")
      assert_instance_of TestProPlan, plan
    end

    test "sandbox_paddle_product_id instance method returns the ID" do
      plan = TestProPlan.instance
      assert_equal "pro_01TEST_SANDBOX", plan.sandbox_paddle_product_id
    end

    test "sandbox_paddle_product_id is nil when not set" do
      plan = TestFreePlan.instance
      assert_nil plan.sandbox_paddle_product_id
    end

    test "all does not duplicate plans with both IDs" do
      classes = PaddleRails::Plan.all.map(&:class)
      assert_equal 1, classes.count { |c| c == TestProPlan }
    end

    # --- Quotas ---

    test "quota returns limit for defined quota" do
      plan = TestProPlan.instance
      assert_equal 50_000, plan.quota(:requests)
      assert_equal 10_000, plan.quota(:storage_mb)
      assert_equal 25, plan.quota(:team_members)
    end

    test "quota returns nil for undefined quota" do
      plan = TestProPlan.instance
      assert_nil plan.quota(:undefined_thing)
    end

    test "within_quota? returns true when under limit" do
      plan = TestProPlan.instance
      assert plan.within_quota?(:requests, current_usage: 30_000)
    end

    test "within_quota? returns true when at limit" do
      plan = TestProPlan.instance
      assert plan.within_quota?(:requests, current_usage: 50_000)
    end

    test "within_quota? returns false when over limit" do
      plan = TestProPlan.instance
      refute plan.within_quota?(:requests, current_usage: 50_001)
    end

    test "within_quota? returns true for undefined quota (unlimited)" do
      plan = TestProPlan.instance
      assert plan.within_quota?(:undefined_thing, current_usage: 999_999)
    end

    test "quota_remaining returns remaining amount" do
      plan = TestProPlan.instance
      assert_equal 20_000, plan.quota_remaining(:requests, current_usage: 30_000)
    end

    test "quota_remaining returns zero when over limit" do
      plan = TestProPlan.instance
      assert_equal 0, plan.quota_remaining(:requests, current_usage: 60_000)
    end

    test "quota_remaining returns nil for undefined quota" do
      plan = TestProPlan.instance
      assert_nil plan.quota_remaining(:undefined_thing, current_usage: 100)
    end

    test "quota_percent_used returns percentage" do
      plan = TestProPlan.instance
      assert_equal 60, plan.quota_percent_used(:requests, current_usage: 30_000)
    end

    test "quota_percent_used returns 100 at limit" do
      plan = TestProPlan.instance
      assert_equal 100, plan.quota_percent_used(:requests, current_usage: 50_000)
    end

    test "quota_percent_used returns nil for undefined quota" do
      plan = TestProPlan.instance
      assert_nil plan.quota_percent_used(:undefined_thing, current_usage: 100)
    end

    # --- has_feature? ---

    test "has_feature? returns true for existing feature" do
      plan = TestProPlan.instance
      assert plan.has_feature?("Priority support")
    end

    test "has_feature? returns false for missing feature" do
      plan = TestProPlan.instance
      refute plan.has_feature?("Nonexistent feature")
    end

    # --- Free plan (no quotas) ---

    test "plan with no quotas has empty quotas hash" do
      plan = TestFreePlan.instance
      assert_empty plan.quotas
    end

    test "plan with no quotas treats all quotas as unlimited" do
      plan = TestFreePlan.instance
      assert plan.within_quota?(:anything, current_usage: 999_999)
      assert_nil plan.quota(:anything)
    end
  end
end
