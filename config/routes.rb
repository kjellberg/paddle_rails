PaddleRails::Engine.routes.draw do
  root "dashboard#show"
  get "onboarding", to: "onboarding#show", as: :onboarding
  post "onboarding/checkout", to: "onboarding#create_checkout", as: :onboarding_checkout
end
