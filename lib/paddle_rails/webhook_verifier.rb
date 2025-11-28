# frozen_string_literal: true

require "openssl"

module PaddleRails
  # Service class for verifying Paddle webhook signatures.
  #
  # Implements Paddle's webhook signature verification as documented at:
  # https://developer.paddle.com/webhooks/signature-verification
  #
  # @example
  #   verifier = PaddleRails::WebhookVerifier.new(secret_key)
  #   if verifier.verify(raw_body, signature_header)
  #     # Webhook is valid
  #   end
  class WebhookVerifier
    # Default tolerance for timestamp validation (5 seconds)
    TIMESTAMP_TOLERANCE = 5

    # @param secret_key [String] The webhook secret key from Paddle
    # @param timestamp_tolerance [Integer] Maximum age of webhook in seconds (default: 5)
    def initialize(secret_key, timestamp_tolerance: TIMESTAMP_TOLERANCE)
      @secret_key = secret_key
      @timestamp_tolerance = timestamp_tolerance
    end

    # Verify a webhook signature.
    #
    # @param raw_body [String] The raw request body (must not be transformed)
    # @param signature_header [String] The value of the Paddle-Signature header
    # @return [Boolean] true if signature is valid, false otherwise
    def verify(raw_body, signature_header)
      return false if raw_body.nil? || signature_header.nil? || @secret_key.nil?

      timestamp, signatures = parse_signature_header(signature_header)
      return false unless timestamp && signatures.any?

      # Check timestamp to prevent replay attacks
      return false unless timestamp_valid?(timestamp)

      # Build signed payload: timestamp:raw_body
      signed_payload = "#{timestamp}:#{raw_body}"

      # Compute expected signature using HMAC-SHA256
      expected_signature = compute_signature(signed_payload)

      # Compare signatures (use timing-safe comparison)
      signatures.any? { |sig| timing_safe_compare(sig, expected_signature) }
    rescue StandardError => e
      Rails.logger.error("PaddleRails::WebhookVerifier: Error verifying signature: #{e.message}")
      false
    end

    private

    # Parse the Paddle-Signature header.
    #
    # Format: "ts=1671552777;h1=eb4d0dc8853be92b7f063b9f3ba5233eb920a09459b6e6b2c26705b4364db151"
    #
    # @param signature_header [String] The Paddle-Signature header value
    # @return [Array<Integer, Array<String>>] [timestamp, array_of_signatures]
    def parse_signature_header(signature_header)
      parts = signature_header.split(";")
      timestamp = nil
      signatures = []

      parts.each do |part|
        key, value = part.split("=", 2)
        case key
        when "ts"
          timestamp = value.to_i
        when "h1"
          signatures << value
        end
      end

      [timestamp, signatures]
    end

    # Check if the timestamp is within the tolerance window.
    #
    # @param timestamp [Integer] Unix timestamp from the webhook
    # @return [Boolean] true if timestamp is valid
    def timestamp_valid?(timestamp)
      current_time = Time.now.to_i
      (current_time - timestamp).abs <= @timestamp_tolerance
    end

    # Compute HMAC-SHA256 signature for the signed payload.
    #
    # @param signed_payload [String] The timestamp:raw_body string
    # @return [String] Hexadecimal signature
    def compute_signature(signed_payload)
      OpenSSL::HMAC.hexdigest("SHA256", @secret_key, signed_payload)
    end

    # Timing-safe string comparison to prevent timing attacks.
    #
    # @param a [String] First string
    # @param b [String] Second string
    # @return [Boolean] true if strings are equal
    def timing_safe_compare(a, b)
      return false if a.nil? || b.nil?
      return false unless a.length == b.length

      OpenSSL.fixed_length_secure_compare(a, b)
    end
  end
end

