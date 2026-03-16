module PaddleRails
  class DashboardController < ApplicationController
    before_action :redirect_to_onboarding_if_no_subscription

    def show
      @subscription = SubscriptionPresenter.new(subscription_owner.subscription)

      # Load plans for change plan widget
      @pricing_plans_mode = PaddleRails.pricing_plans_available?
      if @pricing_plans_mode
        current_plan = ::PricingPlans::PlanResolver.effective_plan_for(subscription_owner)
        @plans = ::PricingPlans.plans.map { |plan| PricingPlanPresenter.new(plan, current_plan: current_plan) }
        @current_price_id = subscription_owner.subscription.items
          .find_by(recurring: true)&.price&.paddle_price_id ||
          subscription_owner.subscription.items.first&.price&.paddle_price_id
      end

      # Load payments for payment history widget
      @payments = if subscription_owner.subscription
                    subscription_owner.subscription.payments.completed.recent.limit(10).map do |payment|
                      PaymentPresenter.new(payment)
                    end
      else
                    []
      end
    end

    private

    def redirect_to_onboarding_if_no_subscription
      return unless subscription_owner

      unless subscription_owner.subscription?
        redirect_to onboarding_path
      end
    end
  end
end
