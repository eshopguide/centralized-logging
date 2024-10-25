# frozen_string_literal: true

CentralEventLogger.configure do |config|
  # Fetch the app_name from environment variables
  config.app_name = ENV.fetch("APP_NAME") # Ensure this ENV variable is set to your app's unique identifier

  # Optional: Set the job queue name
  config.job_queue_name = ENV.fetch("REPORTING_JOB_QUEUE", :default)
  config.api_base_url = ENV["CENTRAL_EVENT_LOGGER_API_BASE_URL"]
  config.api_key = ENV["CENTRAL_EVENT_LOGGER_API_KEY"]
  config.api_secret = ENV["CENTRAL_EVENT_LOGGER_API_SECRET"]

  # if different in this app
  # config.shop_attribute_mappings = {
  #  domain: :myshopify_domain,
  #  name: :name,
  #  email: :email,
  #  owner: :shop_owner
  # }
end
