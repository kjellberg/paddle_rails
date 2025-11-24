module PaddleRails
  class SubscriptionPlan < ApplicationRecord
    self.table_name = "paddle_rails_subscription_plans"
    self.inheritance_column = nil # Disable STI since we use 'type' for Paddle product type

    has_many :prices, class_name: "PaddleRails::SubscriptionPrice", foreign_key: "subscription_plan_id", dependent: :destroy

    validates :paddle_product_id, presence: true, uniqueness: true

    scope :active, -> { where(status: "active") }
    scope :archived, -> { where(status: "archived") }
  end
end
