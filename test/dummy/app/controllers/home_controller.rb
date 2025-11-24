class HomeController < ApplicationController
  def index
    @plans = PaddleRails::SubscriptionPlan.active.includes(:prices).order(:name)
  end
end

