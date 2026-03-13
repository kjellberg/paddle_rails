# frozen_string_literal: true

class StarterPlan < PaddleRails::Plan
  paddle_product_id "pro_01kkh209715xvqmb6ttwdrv7p5"
  sandbox_paddle_product_id "pro_01kkh209715xvqmb6ttwdrv7p5"

  title "Starter"
  description "For individuals and small projects getting started"

  features [
    "<strong>5,000</strong> requests per month",
    "<strong>1 GB</strong> storage",
    "Community support",
    "Basic analytics"
  ]

  quota :requests,   limit: 5_000
  quota :storage_mb, limit: 1_024
end
