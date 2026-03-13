# frozen_string_literal: true

module PaddleRails
  class Product < ApplicationRecord
    self.table_name = "paddle_rails_products"
    self.inheritance_column = nil # Disable STI since we use 'type' for Paddle product type

    has_many :prices, class_name: "PaddleRails::Price", foreign_key: "product_id", dependent: :destroy

    validates :paddle_product_id, presence: true, uniqueness: true

    scope :active, -> { where(status: "active") }
    scope :archived, -> { where(status: "archived") }

    # Returns the Plan DSL object for this product, if one is registered.
    # @return [PaddleRails::Plan, nil]
    def plan
      PaddleRails::Plan.for_product_id(paddle_product_id)
    end
  end
end

