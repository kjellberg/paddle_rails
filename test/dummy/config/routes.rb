Rails.application.routes.draw do
  mount PaddleRails::Engine => "/billing"

  root "home#index"
end
