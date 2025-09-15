# frozen_string_literal: true

Bundler.require :default, :development

# Initialize only the frameworks needed for this gem to avoid CI issues
# with full-stack initialization on certain Rails/Ruby combos
Combustion.initialize! :active_record, :active_job

require "rspec/rails"

ENV["RAILS_ENV"] ||= "test"

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "spec_helper"
require "database_cleaner"
require "factory_bot_rails"
require "ffaker"
require "simplecov"
require "webmock/rspec"
require "central_event_logger"
require_relative "../config/initializers/central_event_logger"
require "rake"
require "dotenv"

# prepare database

Rails.application.load_tasks

# Load custom tasks from spec/tasks
Dir[Rails.root.join("spec/tasks/**/*.rake")].each { |f| load f }

RSpec.configure do |config|
  config.before(:suite) do
    Rake::Task["db:create"].invoke unless ActiveRecord::Base.connection.table_exists?("schema_migrations")
    Rake::Task["db:schema:load"].invoke
  end
end

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migrator.migrations_paths = [Rails.root.join("db/migrate").to_s]
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

SimpleCov.start

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # Clean database with transactions
  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  # Use truncation in feature specs
  config.before(:each, type: :feature) do
    # :rack_test driver's Rack app under test shares database connection
    # with the specs, so continue to use transaction strategy for speed.

    unless driver_shares_db_connection_with_specs
      # Driver is probably for an external browser with an app
      # under test that does *not* share a database connection with the
      # specs, so use truncation strategy.
      DatabaseCleaner.strategy = :truncation
    end
  end

  # Start DatabaseCleaner and clear mail deliveries before every example
  config.before do
    DatabaseCleaner.start
  end

  # Clean database after every example
  config.after do
    DatabaseCleaner.clean
  end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include FactoryBot::Syntax::Methods
  config.include ActiveJob::TestHelper, type: :job

  Dotenv.load(".env.test")
end
