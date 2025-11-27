# frozen_string_literal: true

module PaddleRails
  class CheckoutController < ApplicationController
    before_action :require_transaction_id

    def show
      # Paddle.js will automatically open the checkout when the transaction ID
      # is passed as a query parameter. No additional logic needed.
    end

    private

    def require_transaction_id
      unless params[:_ptxn].present?
        redirect_to onboarding_path, alert: "Invalid checkout session. Please try again."
      end
    end
  end
end

