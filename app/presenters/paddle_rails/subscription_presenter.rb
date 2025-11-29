# frozen_string_literal: true

module PaddleRails
  class SubscriptionPresenter
    attr_reader :subscription

    delegate :status, :items, to: :subscription

    def initialize(subscription)
      @subscription = subscription
    end

    def product_name
      subscription.product&.name || "Subscription"
    end

    def product_initial
      (subscription.product&.name&.chars&.first || "S").upcase
    end

    def status_label
      status.titleize
    end

    def amount
      total_cents = items.sum do |item|
        next 0 unless item.price && item.price.unit_price
        item.price.unit_price * item.quantity
      end
      (total_cents / 100.0)
    end

    def currency
      # Assuming all items have the same currency, which is standard for a single subscription.
      # We can check the first item's price currency.
      first_item_with_price = items.find { |i| i.price.present? }
      return "" unless first_item_with_price
      first_item_with_price.price.currency.upcase
    end

    def formatted_amount
      # We'll let the view handle number_to_currency for now to keep view helpers available.
      amount
    end

    def currency_symbol
      return "$" if currency.blank?
      currency == "EUR" ? "€" : "$"
    end
    
    def interval_label
      # Use the interval from the first recurring item, or fallback to the first item.
      # Usually all items in a subscription share the billing cycle.
      item = items.find { |i| i.recurring? && i.price.present? } || items.find { |i| i.price.present? }
      return "" unless item&.price
      
      interval = item.price.billing_interval
      count = item.price.billing_interval_count || 1

      case interval
      when "month" then (count == 1 ? "month" : "#{count} months")
      when "year" then (count == 1 ? "year" : "#{count} years")
      else interval
      end
    end

    def billing_date_title
      if subscription.scheduled_for_cancellation?
        "Scheduled for cancellation"
      elsif subscription.canceled?
        "Canceled on"
      else
        "Next billing date"
      end
    end

    def billing_date
      date = if subscription.scheduled_for_cancellation?
               subscription.scheduled_cancelation_at
             elsif subscription.canceled?
               subscription.updated_at
             else
               subscription.current_period_end_at
             end
      
      date&.strftime("%B %d, %Y") || "N/A"
    end

    def price_display_text
      return "Custom plan" if amount.zero?
      # View will handle currency formatting
      nil
    end

    def has_price?
      amount > 0
    end

    def payment_method_type
      subscription.payment_method_type
    end

    def has_payment_method?
      subscription.payment_method_id.present?
    end

    def card_brand
      return nil unless has_payment_method?
      details = subscription.payment_method_details || {}
      card = details["card"] || details[:card] || {}
      (card["brand"] || card[:brand] || "").upcase
    end

    def card_last4
      return nil unless has_payment_method?
      details = subscription.payment_method_details || {}
      card = details["card"] || details[:card] || {}
      card["last4"] || card[:last4]
    end

    def card_expiration
      return nil unless has_payment_method?
      details = subscription.payment_method_details || {}
      card = details["card"] || details[:card] || {}
      month = card["expiry_month"] || card[:expiry_month]
      year = card["expiry_year"] || card[:expiry_year]
      
      return nil unless month && year
      
      # Format as MM/YYYY
      "#{month.to_s.rjust(2, '0')}/#{year}"
    end

    def payment_method_icon
      # Return the brand name for display in the icon area
      # This can be styled with CSS to show appropriate icons
      card_brand.presence || "CARD"
    end

    private
    
    # Removed def price as we now calculate totals across all items
  end
end

