# frozen_string_literal: true

require_relative "lib/central_event_logger/version"

Gem::Specification.new do |spec|
  spec.name = "central_event_logger"
  spec.version = CentralEventLogger::VERSION
  spec.authors = ["DaveEshopGuide"]
  spec.email = ["dave@eshop-guide.de"]

  spec.summary = "This gem provides a simple interface for logging events to a centralized database."
  spec.description = "This gem provides a simple interface for logging events to a centralized database. It is designed to be used in Rails applications to log events to a separate reporting database."
  spec.homepage = "https://eshop-guide.de"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org/'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/eshopguide/centralized-logging"
  spec.metadata["changelog_uri"] = "https://github.com/eshopguide/centralized-logging/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "pg", "~> 1.1"
  spec.add_dependency "rails", "~> 7.0"
  spec.add_dependency "tzinfo-data", "~> 1.2024.2"

  spec.add_development_dependency "combustion", "~> 1.3"
  spec.add_development_dependency "database_cleaner", "~> 2.0"
  spec.add_development_dependency "dotenv-rails", "~> 2.8"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2"
  spec.add_development_dependency "ffaker", "~> 2.18"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "rubocop-performance", "~> 1.15"
  spec.add_development_dependency "rubocop-rails", "~> 2.17"
  spec.add_development_dependency "rubocop-rspec", "~> 2.15"
  spec.add_development_dependency "simplecov", "~> 0.21"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "dotenv", "~> 2.8"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
