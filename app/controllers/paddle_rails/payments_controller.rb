# frozen_string_literal: true

module PaddleRails
  class PaymentsController < ApplicationController
    # View invoice in browser (disposition: inline)
    # GET /payments/:id/invoice
    def view_invoice
      payment = find_payment
      return unless payment

      redirect_to_invoice(payment, disposition: "inline")
    end

    # Download invoice as PDF (disposition: attachment)
    # GET /payments/:id/download
    def download_invoice
      payment = find_payment
      return unless payment

      redirect_to_invoice(payment, disposition: "attachment")
    end

    private

    def find_payment
      payment = Payment.find_by(id: params[:id])

      unless payment
        redirect_to root_path, alert: "Payment not found."
        return nil
      end

      # Verify the payment belongs to the current subscription owner
      unless payment.owner == subscription_owner
        redirect_to root_path, alert: "Access denied."
        return nil
      end

      payment
    end

    def redirect_to_invoice(payment, disposition:)
      unless payment.paddle_transaction_id.present?
        redirect_to root_path, alert: "No invoice available for this payment."
        return
      end

      begin
        invoice_url = Paddle::Transaction.invoice(
          id: payment.paddle_transaction_id,
          disposition: disposition
        )

        redirect_to invoice_url, allow_other_host: true
      rescue Paddle::Error => e
        Rails.logger.error("PaddleRails::PaymentsController: Failed to get invoice: #{e.message}")
        redirect_to root_path, alert: "Failed to retrieve invoice. Please try again."
      end
    end
  end
end
