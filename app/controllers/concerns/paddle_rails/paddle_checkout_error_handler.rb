# frozen_string_literal: true

module PaddleRails
  module PaddleCheckoutErrorHandler
    extend ActiveSupport::Concern

    included do
      rescue_from Paddle::Errors::BadRequestError, with: :handle_paddle_bad_request_error
      rescue_from StandardError, with: :handle_paddle_checkout_error
    end

    private

    # Handles Paddle::Errors::BadRequestError with special handling for domain approval errors in development.
    #
    # @param error [Paddle::Errors::BadRequestError] the error to handle
    # @return [void]
    def handle_paddle_bad_request_error(error)
      # Only handle errors for checkout actions
      unless action_name == "create_checkout"
        raise error
      end

      if error.message.include?("transaction_checkout_url_domain_is_not_approved") &&
         defined?(Rails) && Rails.env.development?

        domain = extract_domain_from_url(paddle_checkout_fallback_url)
        error_message = build_domain_approval_error_message(domain)
        redirect_to paddle_checkout_fallback_path, alert: error_message.html_safe
      else
        Rails.logger.error("PaddleRails::PaddleCheckoutErrorHandler: Error creating checkout: #{error.message}")
        redirect_to paddle_checkout_fallback_path, alert: "Failed to create checkout. Please try again."
      end
    end

    # Handles general Paddle checkout errors.
    #
    # @param error [Exception] the error to handle
    # @return [void]
    def handle_paddle_checkout_error(error)
      # Only handle errors for checkout actions
      unless action_name == "create_checkout"
        raise error
      end

      # Check if this is actually a BadRequestError that wasn't caught (shouldn't happen, but just in case)
      if error.is_a?(Paddle::Errors::BadRequestError)
        handle_paddle_bad_request_error(error)
        return
      end

      Rails.logger.error("PaddleRails::PaddleCheckoutErrorHandler: StandardError - #{error.class}: #{error.message}")
      redirect_to paddle_checkout_fallback_path, alert: "Failed to create checkout. Please try again."
    end

    # Returns the fallback path for checkout errors. Override in controller if needed.
    #
    # @return [String, Symbol]
    def paddle_checkout_fallback_path
      onboarding_path
    end

    # Returns the current URL for domain extraction. Override in controller if needed.
    #
    # @return [String, nil]
    def paddle_checkout_fallback_url
      onboarding_url
    end

    def extract_domain_from_url(url)
      return "localhost" unless url

      URI.parse(url).host
    rescue StandardError
      "localhost"
    end

    def build_domain_approval_error_message(domain)
      <<~MSG.squish
        Your checkout_url domain (#{domain}) is not approved by Paddle.
        For development and local testing, you can either:
        (1) run your app behind a reverse proxy like Ngrok or Cloudflare Tunnel and add the assigned HTTPS domain,
        or (2) use a local hostname via /etc/hosts (e.g., application.local) and add it to your Paddle "Approved Domains" settings.
        <a href="https://sandbox-vendors.paddle.com/request-domain-approval" target="_blank" rel="noopener noreferrer" class="underline font-medium hover:text-red-900">Request domain approval</a>.
      MSG
    end
  end
end

