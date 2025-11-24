module PaddleRails
  class Engine < ::Rails::Engine
    isolate_namespace PaddleRails

    initializer "paddle_rails.configuration" do
      Paddle.configure do |config|
        config.environment = ENV.fetch("PADDLE_ENVIRONMENT", "sandbox").to_sym
        config.api_key = ENV.fetch("PADDLE_API_KEY")
      end
    end
  end
end
