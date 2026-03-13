# frozen_string_literal: true

class ProPlan < PaddleRails::Plan
  paddle_product_id "pro_01kkh22gz3cc0vmpfvxdste3qn"
  sandbox_paddle_product_id "pro_01kkh22gz3cc0vmpfvxdste3qn"

  title "Pro"
  description "For growing teams &mdash; <strong>unlimited</strong> projects included"

  features [
    "<strong>50,000</strong> requests per month",
    "<strong>50 GB</strong> storage",
    "Priority email support",
    "Advanced analytics"
  ]

  quota :requests,     limit: 50_000
  quota :storage_mb,   limit: 51_200
  quota :team_members, limit: 10
end
