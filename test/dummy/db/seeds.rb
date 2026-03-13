# frozen_string_literal: true

puts "Seeding demo data..."

# --- Products ---

starter = PaddleRails::Product.find_or_create_by!(paddle_product_id: "pro_01kkh209715xvqmb6ttwdrv7p5") do |p|
  p.name = "Starter"
  p.description = "For individuals and small projects"
  p.status = "active"
  p.tax_category = "standard"
end

pro = PaddleRails::Product.find_or_create_by!(paddle_product_id: "pro_01kkh22gz3cc0vmpfvxdste3qn") do |p|
  p.name = "Pro"
  p.description = "For growing teams"
  p.status = "active"
  p.tax_category = "standard"
end

enterprise = PaddleRails::Product.find_or_create_by!(paddle_product_id: "pro_01kkh245fdbe0fdr9z9gz84y3v") do |p|
  p.name = "Enterprise"
  p.description = "For organizations"
  p.status = "active"
  p.tax_category = "standard"
end

puts "  Created #{PaddleRails::Product.count} products"

# --- Prices ---

# Starter: $9/month, $90/year
PaddleRails::Price.find_or_create_by!(paddle_price_id: "pri_demo_starter_monthly") do |p|
  p.product = starter
  p.name = "Starter Monthly"
  p.unit_price = 900
  p.currency = "USD"
  p.billing_interval = "month"
  p.billing_interval_count = 1
  p.status = "active"
  p.tax_mode = "account_setting"
end

PaddleRails::Price.find_or_create_by!(paddle_price_id: "pri_demo_starter_yearly") do |p|
  p.product = starter
  p.name = "Starter Yearly"
  p.unit_price = 9000
  p.currency = "USD"
  p.billing_interval = "year"
  p.billing_interval_count = 1
  p.status = "active"
  p.tax_mode = "account_setting"
end

# Pro: $29/month, $290/year
PaddleRails::Price.find_or_create_by!(paddle_price_id: "pri_demo_pro_monthly") do |p|
  p.product = pro
  p.name = "Pro Monthly"
  p.unit_price = 2900
  p.currency = "USD"
  p.billing_interval = "month"
  p.billing_interval_count = 1
  p.status = "active"
  p.tax_mode = "account_setting"
end

PaddleRails::Price.find_or_create_by!(paddle_price_id: "pri_demo_pro_yearly") do |p|
  p.product = pro
  p.name = "Pro Yearly"
  p.unit_price = 29000
  p.currency = "USD"
  p.billing_interval = "year"
  p.billing_interval_count = 1
  p.status = "active"
  p.tax_mode = "account_setting"
end

# Enterprise: $99/month, $990/year
PaddleRails::Price.find_or_create_by!(paddle_price_id: "pri_demo_enterprise_monthly") do |p|
  p.product = enterprise
  p.name = "Enterprise Monthly"
  p.unit_price = 9900
  p.currency = "USD"
  p.billing_interval = "month"
  p.billing_interval_count = 1
  p.status = "active"
  p.tax_mode = "account_setting"
end

PaddleRails::Price.find_or_create_by!(paddle_price_id: "pri_demo_enterprise_yearly") do |p|
  p.product = enterprise
  p.name = "Enterprise Yearly"
  p.unit_price = 99000
  p.currency = "USD"
  p.billing_interval = "year"
  p.billing_interval_count = 1
  p.status = "active"
  p.tax_mode = "account_setting"
end

puts "  Created #{PaddleRails::Price.count} prices"

# --- Demo user with active Pro subscription ---

user = User.find_or_create_by!(name: "Jane Demo")

pro_monthly_price = PaddleRails::Price.find_by!(paddle_price_id: "pri_demo_pro_monthly")

subscription = PaddleRails::Subscription.find_or_create_by!(paddle_subscription_id: "sub_demo_001") do |s|
  s.owner = user
  s.status = "active"
  s.current_period_end_at = 30.days.from_now
  s.payment_method_type = "card"
  s.payment_method_details = { type: "card", card: { brand: "visa", last4: "4242", expiry_month: 12, expiry_year: 2027 } }
end

PaddleRails::SubscriptionItem.find_or_create_by!(subscription: subscription, price: pro_monthly_price) do |item|
  item.product = pro
  item.quantity = 1
  item.recurring = true
  item.status = "active"
end

puts "  Created subscription for #{user.name} (#{subscription.status}, #{pro.name})"

# --- Payment history ---

3.times do |i|
  billed_at = (i + 1).months.ago
  PaddleRails::Payment.find_or_create_by!(paddle_transaction_id: "txn_demo_#{format("%03d", i + 1)}") do |p|
    p.subscription = subscription
    p.owner = user
    p.status = "completed"
    p.currency = "USD"
    p.subtotal = 2900
    p.tax = 0
    p.total = 2900
    p.billed_at = billed_at
    p.invoice_number = "INV-2025-#{format("%04d", i + 1)}"
    p.origin = "subscription_recurring"
    p.details = {
      line_items: [
        { product: { name: "Pro" }, price: { unit_price: 2900 }, quantity: 1 }
      ]
    }
  end
end

puts "  Created #{PaddleRails::Payment.count} payments"
puts "Done! Visit /billing to see the demo."
