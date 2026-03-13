class User < ApplicationRecord
  include PaddleRails::Subscribable

  def email
    "#{name.to_s.parameterize}@example.com"
  end
end
