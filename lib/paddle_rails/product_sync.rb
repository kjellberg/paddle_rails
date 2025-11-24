module PaddleRails
  class ProductSync
    def self.call
      new.call
    end

    def call
      sync_products
      sync_prices
    end

    private

    def sync_products
      page = 1
      per_page = 50
      loop do
        products = Paddle::Product.list(per_page: per_page, page: page)
        break if products.data.empty?
        
        products.data.each do |product|
          sync_product(product)
        end
        
        # Check if there are more pages by comparing current page size with total
        break if (page * per_page) >= products.total
        page += 1
      end
    end

    def sync_product(product_data)
      plan = SubscriptionPlan.find_or_initialize_by(paddle_product_id: product_data.id)
      
      plan.assign_attributes(
        name: product_data.name,
        description: product_data.description,
        status: product_data.status,
        type: product_data.type,
        tax_category: product_data.tax_category,
        image_url: product_data.image_url,
        custom_data: product_data.custom_data
      )
      
      plan.save!
    rescue StandardError => e
      Rails.logger.error("PaddleRails::ProductSync: Failed to sync product #{product_data.id}: #{e.message}")
      raise
    end

    def sync_prices
      page = 1
      per_page = 50
      loop do
        prices = Paddle::Price.list(per_page: per_page, page: page)
        break if prices.data.empty?
        
        prices.data.each do |price|
          sync_price(price)
        end
        
        # Check if there are more pages by comparing current page size with total
        break if (page * per_page) >= prices.total
        page += 1
      end
    end

    def sync_price(price_data)
      # Find the subscription plan by product_id
      plan = SubscriptionPlan.find_by(paddle_product_id: price_data.product_id)
      unless plan
        Rails.logger.warn("PaddleRails::ProductSync: Skipping price #{price_data.id} - product #{price_data.product_id} not found locally")
        return
      end

      price = SubscriptionPrice.find_or_initialize_by(paddle_price_id: price_data.id)
      
      # Extract billing cycle info (OpenStruct from paddle gem)
      billing_interval = price_data.billing_cycle&.interval
      billing_interval_count = price_data.billing_cycle&.frequency
      
      # Extract unit price info (OpenStruct from paddle gem)
      unit_price_amount = price_data.unit_price&.amount&.to_i
      currency_code = price_data.unit_price&.currency_code
      
      # Extract trial period (store as JSON, extract days if available)
      trial_period = price_data.trial_period
      trial_days = extract_trial_days(trial_period)
      
      # Extract quantity constraints
      quantity_minimum = price_data.quantity&.minimum
      quantity_maximum = price_data.quantity&.maximum
      
      price.assign_attributes(
        subscription_plan: plan,
        name: price_data.name,
        description: price_data.description,
        status: price_data.status,
        type: price_data.type,
        currency: currency_code,
        unit_price: unit_price_amount,
        billing_interval: billing_interval,
        billing_interval_count: billing_interval_count,
        trial_days: trial_days,
        trial_period: trial_period,
        tax_mode: price_data.tax_mode,
        quantity_minimum: quantity_minimum,
        quantity_maximum: quantity_maximum,
        custom_data: price_data.custom_data
      )
      
      price.save!
    rescue StandardError => e
      Rails.logger.error("PaddleRails::ProductSync: Failed to sync price #{price_data.id}: #{e.message}")
      raise
    end

    def extract_trial_days(trial_period)
      return nil unless trial_period
      
      # trial_period is OpenStruct from paddle gem
      # Common structure: interval: "day", frequency: 14
      return trial_period.frequency if trial_period.interval == "day"
      
      nil
    end
  end
end

