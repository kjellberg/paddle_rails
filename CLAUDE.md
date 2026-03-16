# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

PaddleRails is a Rails engine gem that provides a complete SaaS billing portal backed by the Paddle billing API. It uses the `paddle` gem (~> 2.6) for API calls. The engine is mounted into host Rails apps and provides subscription management, checkout, webhooks, and payment history.

## Commands

```bash
# Run all tests
bin/rails db:test:prepare && bin/rails test

# Run a single test file
bin/rails test test/models/paddle_rails/subscription_test.rb

# Run a single test by name
bin/rails test test/models/paddle_rails/subscription_test.rb -n test_method_name

# Lint
bin/rubocop

# Lint with autocorrect
bin/rubocop -a

# Build Tailwind CSS (watches for changes)
npx tailwindcss -i ./app/assets/tailwind/application.css -o ./app/assets/stylesheets/paddle_rails/tailwind.css --watch

# Rails console (runs against test/dummy app)
bin/rails console
```

## Architecture

### Rails Engine (isolated namespace)

All models, controllers, jobs, and views live under the `PaddleRails` namespace. The engine is mounted by host apps (e.g., `mount PaddleRails::Engine => "/billing"`). A webhook route (`POST /paddle_rails/webhooks`) is automatically prepended to the host app's routes via an engine initializer.

### Owner Identity

Subscriptions use **polymorphic associations** (`belongs_to :owner, polymorphic: true`). Owner identity is passed through Paddle's `custom_data` using **SignedGlobalID** (`owner_sgid` key), which provides tamper-proof resolution when webhooks arrive.

### Service Objects (lib/paddle_rails/)

- **ProductSync** — fetches products/prices from Paddle API, upserts local records
- **Checkout** — creates Paddle transactions, injects owner SGID into custom_data
- **WebhookVerifier** — HMAC-SHA256 signature verification with timing-safe comparison
- **WebhookProcessor** — routes webhook events to handlers, emits `ActiveSupport::Notifications` (format: `paddle_rails.{event_type}`)
- **SubscriptionSync** — syncs subscription state from webhook payloads, resolves owner from SGID
- **Configuration** — DSL block configuration (`PaddleRails.configure { |c| ... }`)

### Webhook Flow

1. `WebhooksController` receives POST, verifies signature, stores `WebhookEvent` audit record
2. `ProcessWebhookJob` processes asynchronously
3. `WebhookProcessor` dispatches to handler by event type
4. Handlers sync data and emit `ActiveSupport::Notifications` for host app listeners

### Presenters

View logic is separated into presenter classes (`SubscriptionPresenter`, `ProductPresenter`, `PaymentPresenter`) rather than helpers or decorators.

### Subscribable Concern

Host app models include `PaddleRails::Subscribable` to gain subscription query methods (e.g., `user.subscriptions`, `user.subscribed?`).

## Code Style

Uses `rubocop-rails-omakase` — the Rails omakase Ruby style guide. No custom overrides.

## Test Setup

Minitest with a dummy Rails app in `test/dummy/`. The dummy app has a `User` model with `include PaddleRails::Subscribable`. Database is SQLite.

## Environment Variables

`PADDLE_API_KEY`, `PADDLE_PUBLIC_TOKEN`, `PADDLE_ENVIRONMENT` (sandbox/production), `PADDLE_WEBHOOK_SECRET` — loaded via dotenv.
