# frozen_string_literal: true

module PaddleRails
  module ApplicationHelper
    # Returns the path to the billing dashboard.
    #
    # This is a convenience helper that provides a clean, global way to
    # reference the PaddleRails billing portal root path.
    #
    # @example
    #   <%= link_to "Manage Billing", billing_dashboard_path %>
    #
    # @return [String] the path to the billing dashboard
    def billing_dashboard_path
      paddle_rails.root_path
    end

    # Returns the URL to the billing dashboard.
    #
    # @example
    #   <%= link_to "Manage Billing", billing_dashboard_url %>
    #
    # @return [String] the URL to the billing dashboard
    def billing_dashboard_url
      paddle_rails.root_url
    end
  end
end
