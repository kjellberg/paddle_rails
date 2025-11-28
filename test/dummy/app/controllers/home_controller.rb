class HomeController < ApplicationController
  def index
    @products = PaddleRails::Product.active.includes(:prices).order(:name)
  end
end

