# frozen_string_literal: true

CentralEventLogger.configure do |config|
  # Fetch the app_name from environment variables
  config.app_name = ENV.fetch("APP_NAME") # Ensure this ENV variable is set to your app's unique identifier

  # Optional: Set the job queue name
  config.job_queue_name = ENV.fetch("REPORTING_JOB_QUEUE", :default)
end
