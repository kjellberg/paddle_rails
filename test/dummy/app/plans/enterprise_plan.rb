# frozen_string_literal: true

class EnterprisePlan < PaddleRails::Plan
  paddle_product_id "pro_01kkh245fdbe0fdr9z9gz84y3v"
  sandbox_paddle_product_id "pro_01kkh245fdbe0fdr9z9gz84y3v"

  title "Enterprise"
  description "For organizations that need <strong>full control</strong> and dedicated support"

  features [
    "<strong>Unlimited</strong> requests",
    "<strong>500 GB</strong> storage",
    "Dedicated account manager",
    "24/7 phone &amp; email support",
  ]

  quota :storage_mb,   limit: 512_000
  quota :team_members, limit: 250
end
