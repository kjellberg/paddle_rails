# PaddleRails

A zero-hassle Paddle subscription integration for Rails using custom_data-based identity.

## Why PaddleRails?

**paddle_rails** solves the common problems with Paddle integrations:

- ✅ **No email mismatches** - Users can change email in Paddle checkout without breaking your app
- ✅ **No customer collisions** - Multiple users can share billing emails safely
- ✅ **No complex customer lookups** - Identity is always resolved via secure custom_data payloads
- ✅ **No Pay gem dependency** - Clean, simple implementation without external abstractions

Instead of syncing users via Paddle Customers, the gem uses a secure custom_data hash (GlobalID) as the single source of truth. This means your app always links subscriptions to the correct user, regardless of email changes or shared billing addresses.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "paddle_rails"
```

And then execute:

```bash
$ bundle install
```

Run the installer:

```bash
$ rails generate paddle:rails:install
```

This will:
- Create an initializer at `config/initializers/paddle_rails.rb`
- Generate a migration for the subscriptions table
- Mount the engine routes at `/paddle`

Run the migration:

```bash
$ rails db:migrate
```

## Configuration

Set the following environment variables:

```bash
PADDLE_API_KEY=your_api_key_here
PADDLE_PUBLIC_TOKEN=your_public_token_here
PADDLE_ENVIRONMENT=production  # or "sandbox"
```

Or configure in the initializer:

```ruby
PaddleRails.configure do |config|
  config.api_key = ENV["PADDLE_API_KEY"]
  config.public_token = ENV["PADDLE_PUBLIC_TOKEN"]
  
  # Configure how to authenticate the subscription owner in the customer portal
  config.subscription_owner_authenticator do
    current_user || warden.authenticate!(scope: :user)
  end
  
  # Configure the back link path in the customer portal sidebar
  config.customer_portal_back_path do
    main_app.root_path  # or main_app.dashboard_path, etc.
  end
end
```

### Configuration Options

- **`api_key`** - Your Paddle API key (defaults to `ENV["PADDLE_API_KEY"]`)
- **`public_token`** - Your Paddle public token (defaults to `ENV["PADDLE_PUBLIC_TOKEN"]`)
- **`subscription_owner_authenticator`** - A proc that returns the current subscription owner. Evaluated in controller/view context. Defaults to `current_user || warden.authenticate!(scope: :user)`
- **`customer_portal_back_path`** - A proc that returns the path for the "Back" link in the customer portal sidebar. Evaluated in controller/view context. Defaults to `main_app.root_path`

## Usage

### 1. Make Your Models Subscribable

Include the `Subscribable` concern in any model:

```ruby
class User < ApplicationRecord
  include PaddleRails::Subscribable
end
```

This gives you:

```ruby
user.subscriptions                      # All subscriptions for the user.
user.subscription                       # Current subscription (if any)
user.subscription?                      # Boolean check

# Access the active plan via the user's current subscription
user.subscription.plan

# Create a Paddle checkout using a Paddle Price ID
user.create_paddle_checkout(paddle_price_id: "pri_123")
```

### 2. Create Checkouts

Create a Paddle checkout for a user:

```ruby
# Get the Paddle Price ID (for example from your own lookup logic)
paddle_price_id = "pri_123"

# Simple checkout using the Paddle Price ID
checkout = user.create_paddle_checkout(paddle_price_id: paddle_price_id)

# With additional options
# Note: custom_data will be merged with a signed owner SGID automatically
checkout = user.create_paddle_checkout(
  paddle_price_id: paddle_price_id,
  custom_data: { foo: "bar" }  # This will be merged with { owner_sgid: "..." }
)
```

The gem automatically injects the owner's GlobalID into the `custom_data` hash, so webhooks will always resolve to the correct user.

### 3. Handle Webhooks

Configure your Paddle webhook endpoint:

1. Go to https://vendors.paddle.com/webhooks
2. Add webhook URL: `https://yourdomain.com/paddle/webhooks`
3. Select events:
   - `subscription.created`
   - `subscription.updated`
   - `subscription.canceled`
   - `transaction.completed`

The gem automatically:
- Verifies webhook signatures
- Resolves the owner from passthrough
- Creates/updates subscription records
- Updates status and billing periods

### 4. Work with Subscriptions

```ruby
# Find subscriptions
subscription = PaddleRails::Subscription.find_by(paddle_subscription_id: "sub_123")

# Check status
subscription.active?
subscription.trialing?
subscription.canceled?
subscription.in_trial?
subscription.current_period_active?

# Scopes
PaddleRails::Subscription.active
PaddleRails::Subscription.trialing
PaddleRails::Subscription.canceled

# Access owner
subscription.owner  # Returns the User, Team, or whatever model owns it
```

### 5. Listen to Subscription Events

Subscribe to ActiveSupport notifications:

```ruby
# In an initializer or application code
ActiveSupport::Notifications.subscribe("paddle_rails.subscription.subscription.created") do |name, start, finish, id, payload|
  subscription = payload[:subscription]
  # Do something when subscription is created
end

ActiveSupport::Notifications.subscribe("paddle_rails.subscription.subscription.updated") do |name, start, finish, id, payload|
  subscription = payload[:subscription]
  # Do something when subscription is updated
end
```

### 6. Work with Products & Prices

`paddle_rails` will keep a local mirror of your Paddle subscription products and prices so you can safely reference them in Rails without hard-coding IDs.

```ruby
# Look up plans and prices by Paddle IDs
plan  = PaddleRails::SubscriptionPlan.find_by(paddle_product_id: "pro_123")
price = PaddleRails::SubscriptionPrice.find_by(paddle_price_id: "pri_123")

# Navigate relationships
plan.prices              # => all prices for the plan
price.subscription_plan  # => owning plan

# Use in your own code (example)
checkout = user.create_paddle_checkout(paddle_price_id: price.paddle_price_id)
```

The catalog is kept in sync with Paddle:

- **Initial sync**: run `bin/rails paddle_rails:sync_products` to pull all products and prices from your Paddle account.
- **Ongoing sync**: schedule the same task (or provided job) to run periodically so new/updated products and prices are mirrored automatically.

## How It Works

### Identity Flow

1. **Checkout Creation**: When you call `user.create_paddle_checkout(paddle_price_id: "pri_123")`, the gem:
   - Creates a custom_data hash: `{ "owner_sgid": "signed-global-id-string" }`
   - Sends this to Paddle with the checkout request (`price_id` plus `custom_data`)
   - Paddle returns a checkout URL

2. **Webhook Processing**: When Paddle sends a webhook:
   - The gem verifies the signature
   - Extracts the custom_data from the event data
   - Resolves the owner: `GlobalID::Locator.locate(custom_data["owner_gid"])`
   - Creates/updates the subscription record

3. **No Customer Dependency**: The gem never looks up Paddle Customers by email or customer_id. Identity is always resolved through the custom_data hash.

### Product & Price Sync

Paddle products and prices are mirrored into two models:

- `PaddleRails::SubscriptionPlan` – mirrors a Paddle Product (e.g. "Pro", "Team").
- `PaddleRails::SubscriptionPrice` – mirrors a Paddle Price (e.g. monthly EUR price for "Pro").

The gem fetches data from the Paddle API and upserts local records so your Rails app always has an up-to-date view of the catalog without calling Paddle on every request.

- The sync task will:
  - Create new plans/prices for any objects that exist in Paddle but not locally.
  - Update names, descriptions, billing intervals, and other metadata when they change in Paddle.
  - Optionally mark missing plans/prices as inactive if they are removed or archived in Paddle.

### Database Schema

The `paddle_rails_subscriptions` table includes:

- `owner_type` / `owner_id` - Polymorphic association to any model
- `subscription_price_id` - Foreign key to `PaddleRails::SubscriptionPrice`
- `paddle_subscription_id` - Paddle's subscription ID (unique)
- `paddle_price_id` - Cached Paddle Price ID for convenience
- `status` - Current status (active, trialing, canceled, etc.)
- `current_period_end_at` - When current billing period ends
- `trial_ends_at` - When trial ends (if applicable)
- `raw_payload` - Full JSON payload from Paddle for reference

The `paddle_rails_subscription_plans` table (Paddle Products) will include fields like:

- `paddle_product_id` - Paddle's product ID (unique)
- `name` - Human-readable name
- `description` - Optional description
- `status` - Whether the plan is active/archived
- Timestamps and any additional Paddle metadata you need

The `paddle_rails_subscription_prices` table (Paddle Prices) will include fields like:

- `subscription_plan_id` - Foreign key to `SubscriptionPlan`
- `paddle_price_id` - Paddle's price ID (unique)
- `currency` - Currency code (e.g. "USD")
- `unit_price` - Price amount (integer, typically in minor units)
- `billing_interval` / `billing_interval_count` - e.g. "month", 1
- `trial_days` - Optional trial length
- Timestamps and any additional Paddle metadata you need

## API Reference

### PaddleRails::Subscribable

Methods available on any model that includes this concern:

- `paddle_subscriptions` - Association to all subscriptions
- `subscription` - Returns the current subscription or nil
- `subscription?` - Returns true if user has a current subscription
- `create_paddle_checkout(paddle_price_id:, **options)` - Creates a Paddle checkout from a raw Paddle Price ID

### PaddleRails::Subscription

Model methods:

- `active?`, `trialing?`, `canceled?`, `paused?` - Status checks
- `in_trial?` - Returns true if currently in trial period
- `current_period_active?` - Returns true if billing period is active
- `owner` - Returns the polymorphic owner (User, Team, etc.)
- `subscription_price` - Returns the associated `PaddleRails::SubscriptionPrice`

Scopes:

- `active`, `trialing`, `past_due`, `canceled`, `paused`

Associations:

- `belongs_to :subscription_price, class_name: "PaddleRails::SubscriptionPrice"`

### PaddleRails::SubscriptionPlan

Represents a Paddle Product.

- `has_many :prices, class_name: "PaddleRails::SubscriptionPrice"`
- `find_by(paddle_product_id:)` - Look up by Paddle product ID
- Suggested scopes: `active`, `archived`

Example usage:

```ruby
plan = PaddleRails::SubscriptionPlan.active.find_by!(paddle_product_id: "pro_123")
plan.prices # => available prices for this plan
```

### PaddleRails::SubscriptionPrice

Represents a Paddle Price belonging to a `SubscriptionPlan`.

- `belongs_to :subscription_plan`
- `find_by(paddle_price_id:)` - Look up by Paddle price ID
- Suggested scopes: `active`, `for_currency("USD")`, `recurring`, `one_time`

Example usage:

```ruby
price = PaddleRails::SubscriptionPrice.for_currency("USD").recurring.first
user.create_paddle_checkout(paddle_price_id: price.paddle_price_id)
```

### PaddleRails::Checkout

Service class for creating checkouts:

```ruby
# Quick helper that returns the hosted checkout URL
checkout_url = PaddleRails::Checkout.url_for(
  owner: user,
  paddle_price_id: "pri_123",
  custom_data: { foo: "bar" }  # optional
)

redirect_to checkout_url, allow_other_host: true
```

If you need the full `Paddle::Transaction` object instead, you can use `.create`:

```ruby
checkout = PaddleRails::Checkout.create(
  owner: user,
  paddle_price_id: "pri_123",
  custom_data: { foo: "bar" }  # optional
)
```

In both cases, the `custom_data` hash you pass will be merged with the owner's
**signed** GlobalID under the `"owner_sgid"` key:

```ruby
{
  "owner_sgid" => user.to_sgid_param(for: "paddle_rails_owner"),
  "foo"        => "bar"
}
```

## Development

After checking out the repo, run:

```bash
bin/setup
```

Run tests:

```bash
bin/rails test
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kjellberg/paddle_rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
