class HomeController < ApplicationController
  def index
    @products = PaddleRails::SubscriptionProduct.active.includes(:prices).order(:name)
  end
end

