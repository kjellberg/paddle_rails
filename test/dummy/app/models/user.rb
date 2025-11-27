class User < ApplicationRecord
  include PaddleRails::Subscribable
  
  def name
    "John Doe"
  end

  def email
    "john.doe.example@mailinator.com"
  end
end
