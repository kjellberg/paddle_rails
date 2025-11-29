PaddleRails::Engine.routes.draw do
  root "dashboard#show"
  get "onboarding", to: "onboarding#show", as: :onboarding
  post "onboarding/checkout", to: "onboarding#create_checkout", as: :onboarding_checkout
  get "checkout", to: "checkout#show", as: :checkout
  get "checkout/check_status/:transaction_id", to: "checkout#check_status", as: :check_transaction_status
  post "subscriptions/revoke_cancellation", to: "subscriptions#revoke_cancellation", as: :revoke_subscription_cancellation
  post "subscriptions/cancel", to: "subscriptions#cancel", as: :cancel_subscription
end
