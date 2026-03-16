# frozen_string_literal: true

module PaddleRails
  # Service object for creating Paddle transactions (checkouts).
  #
  # Wraps {Paddle::Transaction.create} and is responsible for:
  # - Building the items array from a Paddle price ID.
  # - Merging the owner's **signed** GlobalID into the `custom_data` hash under
  #   the \"owner_sgid\" key, so the owner reference is tamper‑evident.
  # - Returning the resulting {Paddle::Transaction} instance.
  #
  # @example Basic usage
  #   checkout = PaddleRails::Checkout.create(
  #     owner: user,
  #     paddle_price_id: "pri_123"
  #   )
  #
  #   redirect_to checkout.details.checkout.url, allow_other_host: true
  #
  # @example With additional custom data
  #   checkout = PaddleRails::Checkout.create(
  #     owner: user,
  #     paddle_price_id: "pri_123",
  #     custom_data: { foo: "bar" }
  #   )
  #
  #   # custom_data will be merged with a signed owner SGID:
  #   # { \"owner_sgid\" => user.to_sgid_param(for: \"paddle_rails_owner\"), \"foo\" => \"bar\" }
  class Checkout
    attr_reader :owner, :paddle_price_id, :custom_data, :checkout_url

    # Create a new checkout (transaction) for a given owner and price.
    #
    # @param owner [Object] the subscription owner (e.g. User) – must support `to_gid_param`
    # @param paddle_price_id [String] the Paddle Price ID used for the transaction
    # @param custom_data [Hash] optional extra metadata to merge into `custom_data`
    # @param checkout_url [String, nil] optional URL that Paddle should use for the checkout
    # @return [Paddle::Transaction] the created transaction
    def self.create(owner:, paddle_price_id:, custom_data: {}, checkout_url: nil)
      new(
        owner: owner,
        paddle_price_id: paddle_price_id,
        custom_data: custom_data,
        checkout_url: checkout_url
      ).create
    end

    # Convenience helper that creates a checkout and returns only the hosted URL.
    #
    # @param owner [Object] the subscription owner (e.g. User)
    # @param paddle_price_id [String] the Paddle Price ID used for the transaction
    # @param custom_data [Hash] optional extra metadata to merge into `custom_data`
    # @param checkout_url [String, nil] optional URL that Paddle should use for the checkout
    # @return [String, nil] the checkout URL, if present
    def self.url_for(owner:, paddle_price_id:, custom_data: {}, checkout_url: nil)
      transaction = create(
        owner: owner,
        paddle_price_id: paddle_price_id,
        custom_data: custom_data,
        checkout_url: checkout_url
      )

      extract_url(transaction)
    end

    # @param owner [Object]
    # @param paddle_price_id [String]
    # @param custom_data [Hash]
    # @param checkout_url [String, nil]
    def initialize(owner:, paddle_price_id:, custom_data: {}, checkout_url: nil)
      @owner = owner
      @paddle_price_id = paddle_price_id
      @custom_data = custom_data || {}
      @checkout_url = checkout_url
    end

    # Perform the transaction creation against the Paddle API.
    #
    # @return [Paddle::Transaction]
    def create
      attrs = {
        items: [ { price_id: paddle_price_id, quantity: 1 } ],
        custom_data: merged_custom_data
      }

      if checkout_url
        attrs[:checkout] = { url: normalize_checkout_url_for_paddle(checkout_url) }
      end

      Paddle::Transaction.create(**attrs)
    end

    private

    def merged_custom_data
      base = { "owner_sgid" => owner_sgid }
      # Stringify keys to keep custom_data consistent with Paddle expectations
      base.merge(stringified_custom_data)
    end

    # Build a signed GlobalID string for the owner that can be verified later.
    #
    # NOTE: Webhook processing is not implemented yet, but when it is, you
    # should resolve this using:
    #
    #   GlobalID::Locator.locate_signed(owner_sgid, for: \"paddle_rails_owner\")
    #
    # @return [String]
    def owner_sgid
      if owner.respond_to?(:to_sgid_param)
        owner.to_sgid_param(for: "paddle_rails_owner")
      elsif defined?(GlobalID::SignedGlobalID)
        GlobalID::SignedGlobalID.create(owner, for: "paddle_rails_owner").to_s
      else
        owner.to_s
      end
    end

    def stringified_custom_data
      custom_data.to_h.transform_keys(&:to_s)
    end

    # In development, convert all http:// URLs to https:// for
    # checkout URLs to avoid Paddle's domain approval error.
    #
    # @param url [String, nil]
    # @return [String, nil]
    def normalize_checkout_url_for_paddle(url)
      return url unless url
      return url unless defined?(Rails) && Rails.env.development?

      url.sub(/\Ahttp:\/\//, "https://")
    end

    # Extract the hosted checkout URL from a Paddle::Transaction.
    #
    # The Paddle gem currently exposes this via an internal OpenStruct
    # where the raw attributes live in `checkout.table`.
    #
    # @param transaction [Paddle::Transaction, nil]
    # @return [String, nil]
    def self.extract_url(transaction)
      return nil unless transaction

      url = nil

      # Preferred: transaction.checkout.table[:url]
      if transaction.respond_to?(:checkout) && transaction.checkout
        checkout = transaction.checkout
        if checkout.respond_to?(:table)
          url = checkout.table[:url] || checkout.table["url"]
        end

        url ||= checkout.url if checkout.respond_to?(:url)
      end

      # Fallback: nested details.checkout.url (for other Paddle shapes)
      if url.nil? && transaction.respond_to?(:details) && transaction.details&.respond_to?(:checkout)
        nested = transaction.details.checkout
        url = nested.url if nested.respond_to?(:url)
      end

      rewrite_localhost_url(url)
    end

    # In development, Paddle may return https URLs which
    # Rails typically serves over plain HTTP. Normalize those so we
    # don't hit mixed-scheme issues in local setups.
    #
    # @param url [String, nil]
    # @return [String, nil]
    def self.rewrite_localhost_url(url)
      return url unless url
      return url unless defined?(Rails) && Rails.env.development?

      url.sub(/\Ahttps:\/\//, "http://")
    end
  end
end
