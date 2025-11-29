# PaddleRails

**The ultimate plug-and-play billing engine for Ruby on Rails and Paddle.**

Building a SaaS? Stop wasting weeks on billing integration. **PaddleRails** is a production-ready Rails engine that drops a complete subscription management portal into your application in minutes.

It's not just an API wrapper—it's a full-stack billing solution that handles the hard parts of SaaS payments: webhooks, plan upgrades, prorations, cancellation flows, and payment method updates. Fully compliant with Paddle Billing (v2), handling global tax/VAT and localized pricing automatically.

No need to build billing UI from scratch. Just mount the engine and focus on your product.

- ✅ **No email mismatches** - Users can change email in Paddle checkout without breaking your app
- ✅ **No customer collisions** - Multiple users can share billing emails safely
- ✅ **No complex customer lookups** - Identity is always resolved via secure custom_data payloads
- ✅ **No Pay gem dependency** - Clean, simple implementation without external abstractions

Instead of syncing users via Paddle Customers, the gem uses a secure custom_data hash (GlobalID) as the single source of truth. This means your app always links subscriptions to the correct user, regardless of email changes or shared billing addresses.

- 🚀 **Instant SaaS Infrastructure** — Mountable billing dashboard ready in minutes
- 💳 **Paddle Billing V2** — Built for the latest Paddle API
- 🔄 **Two-Way Sync** — Webhooks keep your local database perfectly synchronized
- 🎨 **Beautiful UI** — Modern, responsive dashboard built with Tailwind CSS
- 🛡 **Identity Secure** — Uses GlobalID for bulletproof user mapping (no email mismatch issues)
- 🏢 **B2B Ready** — Supports subscriptions on Users, Teams, Organizations, or Tenants

## Quick Start

### 1. Install the gem

```ruby
# Gemfile
gem "paddle_rails"
```

```bash
$ bundle install
```

Install the migrations to create the necessary tables:

```bash
$ bin/rails paddle_rails:install:migrations
$ bin/rails db:migrate
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

Add this to your `config/routes.rb`:

```ruby
mount PaddleRails::Engine => "/billing"
```

### 4. Make your model subscribable

You can add subscription capabilities to **any** model—`User`, `Organization`, `Team`, `Tenant`, or `Domain`.

```ruby
class User < ApplicationRecord
  include PaddleRails::Subscribable
end
```

### 5. Sync your Paddle products

To import your products and prices from Paddle, add the sync command to your `db/seeds.rb`:

```ruby
# db/seeds.rb
puts "Syncing Paddle products..."
PaddleRails::ProductSync.call
```

Then run:

```bash
$ bin/rails db:seed
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
  
  # How to identify the subscription owner in the billing portal
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

- **Products & Prices** — Use `PaddleRails::ProductSync.call` to mirror your Paddle catalog
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
current_user.subscription.scheduled_for_cancellation?
```

## Customization

### Override Views

Copy the views to your application to customize:

```bash
$ bin/rails generate paddle_rails:views
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
