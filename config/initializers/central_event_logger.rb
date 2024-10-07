# frozen_string_literal: true

CentralEventLogger.configure do |config|
  # Use a database URL from the environment variables
  config.reporting_database = ENV.fetch('REPORTING_DATABASE_URL')

  # Fetch the app_id from environment variables
  config.app_id = ENV.fetch('APP_ID') # Ensure this ENV variable is set to your app's unique identifier

  # Optional: Set the job queue name
  config.job_queue_name = :event_logging
end
