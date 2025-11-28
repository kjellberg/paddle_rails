# frozen_string_literal: true

module PaddleRails
  class Subscription < ApplicationRecord
    self.table_name = "paddle_rails_subscriptions"

    # Statuses
    ACTIVE = "active"
    TRIALING = "trialing"
    PAST_DUE = "past_due"
    PAUSED = "paused"
    CANCELED = "canceled"

    belongs_to :owner, polymorphic: true
    has_many :items, class_name: "PaddleRails::SubscriptionItem", dependent: :destroy
    has_many :prices, through: :items, source: :subscription_price
    has_many :plans, through: :prices, source: :subscription_plan

    validates :paddle_subscription_id, presence: true, uniqueness: true
    validates :status, presence: true

    scope :active, -> { where(status: ACTIVE) }
    scope :trialing, -> { where(status: TRIALING) }
    scope :past_due, -> { where(status: PAST_DUE) }
    scope :paused, -> { where(status: PAUSED) }
    scope :canceled, -> { where(status: CANCELED) }

    # Returns true if the subscription is active.
    # @return [Boolean]
    def active?
      status == ACTIVE
    end

    # Returns true if the subscription is trialing.
    # @return [Boolean]
    def trialing?
      status == TRIALING
    end

    # Returns true if the subscription is paused.
    # @return [Boolean]
    def paused?
      status == PAUSED
    end

    # Returns true if the subscription is canceled.
    # @return [Boolean]
    def canceled?
      status == CANCELED
    end

    # Returns true if the subscription is currently in a trial period.
    # @return [Boolean]
    def in_trial?
      trial_ends_at.present? && trial_ends_at > Time.current
    end

    # Returns true if the current period is active (not expired).
    # @return [Boolean]
    def current_period_active?
      current_period_end_at.present? && current_period_end_at > Time.current
    end

    # Returns the primary plan for this subscription.
    # Uses the first recurring item's plan, or falls back to the first item's plan.
    # @return [PaddleRails::SubscriptionPlan, nil]
    def plan
      # Try to get plan from first recurring item
      first_recurring_item = items.find_by(recurring: true)
      return first_recurring_item&.plan if first_recurring_item

      # Fallback to first item
      items.first&.plan
    end
  end
end

