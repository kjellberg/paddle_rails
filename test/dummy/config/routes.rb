Rails.application.routes.draw do
  mount PaddleRails::Engine => "/billing", as: "billing"

  root "home#index"
end
