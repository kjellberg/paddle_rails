# PaddleRails

A plug-and-play billing portal for Rails applications using Paddle Billing.

## What is PaddleRails?

**PaddleRails** is a Rails engine that provides a complete, ready-to-use billing dashboard for your SaaS application. Mount it, configure your Paddle credentials, and you instantly have:

- **Plan Selection & Checkout** — Beautiful onboarding flow with your Paddle products and prices
- **Subscription Dashboard** — Current plan, billing dates, and subscription status
- **Payment Method Management** — View and update card details
- **Cancel & Resume** — Self-service subscription cancellation with one-click undo
- **Automatic Webhook Handling** — Subscriptions stay in sync with Paddle automatically

No need to build billing UI from scratch. Just mount the engine and focus on your product.

## Quick Start

### 1. Install the gem

```ruby
# Gemfile
gem "paddle_rails"
```

```bash
$ bundle install
$ rails generate paddle:rails:install
$ rails db:migrate
```

### 2. Configure Paddle credentials

```bash
# .env or environment variables
PADDLE_API_KEY=your_api_key
PADDLE_PUBLIC_TOKEN=your_public_token
PADDLE_ENVIRONMENT=sandbox  # or "production"
PADDLE_WEBHOOK_SECRET=your_webhook_secret
```

### 3. Mount the billing portal

The installer adds this to your `routes.rb`:

```ruby
mount PaddleRails::Engine => "/billing"
```

### 4. Make your User model subscribable

```ruby
class User < ApplicationRecord
  include PaddleRails::Subscribable
end
```

### 5. Sync your Paddle products

```bash
$ rails paddle_rails:sync_products
```

### 6. Configure webhooks in Paddle

Go to your [Paddle notification settings](https://vendors.paddle.com/notifications-v2) and add:

- **URL**: `https://yourdomain.com/paddle_rails/webhooks`
- **Events**: `subscription.created`, `subscription.updated`, `subscription.canceled`, `transaction.completed`

**That's it!** Visit `/billing` to see your billing portal.

## The Billing Portal

Once mounted, PaddleRails provides these pages automatically:

| Path | Description |
|------|-------------|
| `/billing` | Main dashboard showing current subscription, payment method, and billing info |
| `/billing/onboarding` | Plan selection page for new subscribers |
| `/billing/checkout` | Inline Paddle checkout experience |

### Dashboard Features

- **Current Subscription** — Shows plan name, price, billing cycle, and next billing date
- **Subscription Status** — Active, trialing, canceled, or scheduled for cancellation
- **Payment Method** — Card brand, last 4 digits, expiration with update button
- **Cancel Subscription** — Schedule cancellation at end of billing period
- **Revoke Cancellation** — One-click to undo a pending cancellation

### Screenshots

The billing portal is designed to be clean and professional out of the box. It uses Tailwind CSS classes and can be customized by overriding the views.

## Configuration

```ruby
# config/initializers/paddle_rails.rb
PaddleRails.configure do |config|
  # Paddle API credentials
  config.api_key = ENV["PADDLE_API_KEY"]
  config.public_token = ENV["PADDLE_PUBLIC_TOKEN"]
  config.environment = ENV["PADDLE_ENVIRONMENT"]  # "sandbox" or "production"
  config.webhook_secret = ENV["PADDLE_WEBHOOK_SECRET"]
  
  # How to identify the current user in the billing portal
  config.subscription_owner_authenticator do
    current_user || warden.authenticate!(scope: :user)
  end
  
  # Where the "Back" link goes in the portal
  config.customer_portal_back_path do
    main_app.root_path
  end
end
```

### Paddle Dashboard Settings

#### Default Payment Link

When customers update their payment method, Paddle redirects them back to your app. Configure the **Default payment link** in your Paddle dashboard:

1. Go to **Checkout Settings**:
   - Sandbox: https://sandbox-vendors.paddle.com/checkout-settings
   - Production: https://vendors.paddle.com/checkout-settings

2. Set **Default payment link** to your billing dashboard URL:
   ```
   https://yourdomain.com/billing
   ```

## How It Works

### Identity via custom_data

PaddleRails uses a secure approach to link Paddle subscriptions to your users:

1. When creating a checkout, the gem injects a signed GlobalID into `custom_data`
2. When webhooks arrive, this ID is used to find the correct user
3. No reliance on email matching or Paddle customer IDs

This means:
- Users can change their email in Paddle checkout without breaking anything
- Multiple users can share billing emails safely
- Identity is always resolved correctly

### Automatic Sync

The gem automatically keeps your local database in sync with Paddle:

- **Products & Prices** — Run `rails paddle_rails:sync_products` to mirror your Paddle catalog
- **Subscriptions** — Webhook handlers automatically create/update subscription records
- **Payment Methods** — Updated automatically when transactions complete

## Checking Subscription Status

```ruby
# In your controllers or views
if current_user.subscription?
  # User has an active subscription
end

# More detailed checks
current_user.subscription.active?
current_user.subscription.trialing?
current_user.subscription.canceled?
current_user.subscription.scheduled_for_cancellation?
```

## Customization

### Override Views

Copy the views to your application to customize:

```bash
$ rails generate paddle_rails:views
```

This copies all views to `app/views/paddle_rails/` where you can modify them.

### Custom Webhook Handling

Listen to Paddle events using ActiveSupport::Notifications:

```ruby
# config/initializers/paddle_rails.rb
ActiveSupport::Notifications.subscribe("paddle_rails.subscription.created") do |name, start, finish, id, payload|
  webhook_event = payload[:webhook_event]
  # Send welcome email, provision resources, etc.
end

ActiveSupport::Notifications.subscribe("paddle_rails.subscription.canceled") do |name, start, finish, id, payload|
  # Handle cancellation
end
```

### Programmatic Checkout

Create checkouts from your own code:

```ruby
# Simple checkout
checkout_url = current_user.create_paddle_checkout(paddle_price_id: "pri_123")
redirect_to checkout_url, allow_other_host: true

# With custom data
checkout_url = current_user.create_paddle_checkout(
  paddle_price_id: "pri_123",
  custom_data: { referral_code: "ABC123" }
)
```

## Models

### PaddleRails::Subscription

```ruby
subscription = current_user.subscription

subscription.active?                    # Currently active
subscription.trialing?                  # In trial period
subscription.canceled?                  # Has been canceled
subscription.scheduled_for_cancellation?  # Will cancel at period end
subscription.current_period_end_at      # Next billing date
subscription.items                      # All subscription items (for multi-product)
```

### PaddleRails::Product & PaddleRails::Price

```ruby
# Your Paddle products, synced locally
PaddleRails::Product.active.each do |product|
  product.name
  product.prices.each do |price|
    price.unit_price  # In minor units (cents)
    price.currency
    price.billing_interval  # "month", "year"
  end
end
```

## Webhook Events

All webhooks are stored in `PaddleRails::WebhookEvent` for debugging and replayability:

```ruby
PaddleRails::WebhookEvent.pending   # Not yet processed
PaddleRails::WebhookEvent.processed # Successfully handled
PaddleRails::WebhookEvent.failed    # Had errors

event = PaddleRails::WebhookEvent.last
event.event_type  # "subscription.created"
event.payload     # Full JSON from Paddle
```

## Development

```bash
$ bin/setup
$ bin/rails test
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kjellberg/paddle_rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
