class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_user

  private

  def set_current_user
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
    end

    unless @current_user
      @current_user = User.create!(name: "User ##{SecureRandom.random_number(1_000_000)}")
      session[:user_id] = @current_user.id
    end
  end

  def current_user
    @current_user
  end
  helper_method :current_user
end
