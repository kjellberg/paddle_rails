# frozen_string_literal: true

module PaddleRails
  class Product < ApplicationRecord
    self.table_name = "paddle_rails_products"
    self.inheritance_column = nil # Disable STI since we use 'type' for Paddle product type

    has_many :prices, class_name: "PaddleRails::Price", foreign_key: "product_id", dependent: :destroy

    validates :paddle_product_id, presence: true, uniqueness: true

    scope :active, -> { where(status: "active") }
    scope :archived, -> { where(status: "archived") }
  end
end

