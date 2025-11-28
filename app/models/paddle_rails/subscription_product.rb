# frozen_string_literal: true

module PaddleRails
  class SubscriptionProduct < ApplicationRecord
    self.table_name = "paddle_rails_subscription_products"
    self.inheritance_column = nil # Disable STI since we use 'type' for Paddle product type

    has_many :prices, class_name: "PaddleRails::SubscriptionPrice", foreign_key: "subscription_product_id", dependent: :destroy

    validates :paddle_product_id, presence: true, uniqueness: true

    scope :active, -> { where(status: "active") }
    scope :archived, -> { where(status: "archived") }
  end
end

