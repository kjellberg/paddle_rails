require_relative "lib/paddle_rails/version"

Gem::Specification.new do |spec|
  spec.name        = "paddle_rails"
  spec.version     = PaddleRails::VERSION
  spec.authors     = [ "Rasmus Kjellberg" ]
  spec.email       = [ "2277443+kjellberg@users.noreply.github.com" ]
  spec.homepage    = "https://github.com/kjellberg/paddle_rails"
  spec.summary     = "Plug-and-play billing engine for Rails + Paddle. Full subscription management portal with webhooks, plan changes, and payment history."
  spec.description = <<~DESC
    PaddleRails is a production-ready Rails engine that drops a complete subscription management portal into your application in minutes.
    
    It's not just an API wrapper—it's a full-stack billing solution that handles the hard parts of SaaS payments: webhooks, plan upgrades, prorations, cancellation flows, and payment method updates. Fully compliant with Paddle Billing (v2), handling global tax/VAT and localized pricing automatically.
    
    Features:
    - Mountable billing dashboard ready in minutes
    - Built for Paddle Billing V2
    - Two-way sync via webhooks
    - Beautiful UI built with Tailwind CSS
    - Uses GlobalID for bulletproof user mapping (no email mismatch issues)
    - Supports subscriptions on Users, Teams, Organizations, or Tenants
    - Payment history with invoice viewing and download
    - Plan upgrades/downgrades with proration
    - Payment method management
    
    No need to build billing UI from scratch. Just mount the engine and focus on your product.
  DESC
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kjellberg/paddle_rails"
  spec.metadata["changelog_uri"] = "https://github.com/kjellberg/paddle_rails/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.1"
  spec.add_dependency "paddle", "~> 2.6"
end
