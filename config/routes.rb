PaddleRails::Engine.routes.draw do
  root "dashboard#show"
  get "onboarding", to: "onboarding#show", as: :onboarding
  post "onboarding/checkout", to: "onboarding#create_checkout", as: :onboarding_checkout
  get "checkout", to: "checkout#show", as: :checkout
  get "checkout/check_status/:transaction_id", to: "checkout#check_status", as: :check_transaction_status
  post "checkout/update_payment_method", to: "checkout#update_payment_method", as: :update_payment_method
  post "subscriptions/revoke_cancellation", to: "subscriptions#revoke_cancellation", as: :revoke_subscription_cancellation
  post "subscriptions/cancel", to: "subscriptions#cancel", as: :cancel_subscription
  post "subscriptions/change_plan", to: "subscriptions#change_plan", as: :change_subscription_plan
  get "payments/:id/invoice", to: "payments#view_invoice", as: :view_payment_invoice
  get "payments/:id/download", to: "payments#download_invoice", as: :download_payment_invoice
end
