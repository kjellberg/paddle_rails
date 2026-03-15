# frozen_string_literal: true

module PaddleRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path("templates", __dir__)

      desc "Install PaddleRails: copy migrations and create initializer"

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def copy_migrations
        rake "paddle_rails:install:migrations"
      end

      def copy_initializer
        template "initializer.rb", "config/initializers/paddle_rails.rb"
      end

      def print_instructions
        say ""
        say "PaddleRails installed successfully!", :green
        say ""
        say "Next steps:"
        say "  1. Run migrations:  bin/rails db:migrate"
        say "  2. Configure credentials via environment variables or Rails credentials"
        say "  3. Mount the engine in config/routes.rb (if not already):"
        say "       mount PaddleRails::Engine => \"/billing\""
        say "  4. Add `include PaddleRails::Subscribable` to your User model"
        say "  5. Sync products:   PaddleRails::ProductSync.call"
        say ""
      end
    end
  end
end
