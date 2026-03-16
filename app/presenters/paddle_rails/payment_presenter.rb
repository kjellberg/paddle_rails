# frozen_string_literal: true

module PaddleRails
  class PaymentPresenter
    attr_reader :payment

    delegate :id, :status, :invoice_id, :invoice_number, :paddle_transaction_id, to: :payment

    def initialize(payment)
      @payment = payment
    end

    # Returns the formatted date of the payment.
    # @return [String]
    def date
      return "N/A" unless payment.billed_at
      payment.billed_at.strftime("%b %d, %Y")
    end

    # Returns a description of the payment.
    # @return [String]
    def description
      payment.description
    end

    # Returns the formatted amount with currency symbol.
    # @return [String]
    def amount
      return "N/A" unless payment.total
      amount_value = payment.amount_in_currency
      currency_symbol = currency_symbol_for(payment.currency)
      sign = credit? ? "+" : "-"
      "#{sign}#{currency_symbol}#{format('%.2f', amount_value.abs)}"
    end

    # Returns the status label for display.
    # @return [String]
    def status_label
      return "Refunded" if credit?

      case payment.status
      when "completed"
        "Paid"
      when "pending"
        "Pending"
      when "failed"
        "Failed"
      else
        payment.status.titleize
      end
    end

    # Returns true if the payment is a credit (negative amount).
    # @return [Boolean]
    def credit?
      payment.total && payment.total < 0
    end

    # Returns the status badge class based on payment status.
    # @return [String]
    def status_badge_class
      case payment.status
      when "completed"
        credit? ? "bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-600/20" : "bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-600/20"
      when "pending"
        "bg-yellow-50 text-yellow-700 ring-1 ring-inset ring-yellow-600/20"
      when "failed"
        "bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/20"
      else
        "bg-slate-50 text-slate-700 ring-1 ring-inset ring-slate-600/20"
      end
    end

    # Returns true if invoice is available.
    # @return [Boolean]
    def has_invoice?
      paddle_transaction_id.present?
    end

    private

    # Returns the currency symbol for a given currency code.
    # @param currency [String] The currency code (e.g., "USD", "EUR")
    # @return [String]
    def currency_symbol_for(currency)
      case currency&.upcase
      when "EUR"
        "€"
      when "GBP"
        "£"
      when "USD"
        "$"
      else
        currency || "$"
      end
    end
  end
end
