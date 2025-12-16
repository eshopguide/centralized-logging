# frozen_string_literal: true

CentralEventLogger.configure do |config|
  # Fetch the app_name from environment variables
  config.app_name = ENV.fetch("APP_NAME") # Ensure this ENV variable is set to your app's unique identifier

  # Optional: Set the job queue name
  config.job_queue_name = ENV.fetch("REPORTING_JOB_QUEUE", :default)
  config.api_base_url = ENV["CENTRAL_EVENT_LOGGER_API_BASE_URL"]
  config.api_key = ENV["CENTRAL_EVENT_LOGGER_API_KEY"]
  config.api_secret = ENV["CENTRAL_EVENT_LOGGER_API_SECRET"]

  # Adapters: set which sinks to send events to. 
  # Available adapters: [:central_api, :posthog, :klaviyo]
  # Example: [:central_api, :posthog, :klaviyo]
  if ENV["CENTRAL_EVENT_LOGGER_ADAPTERS"]
    # comma separated list like: central_api,posthog,klaviyo
    config.adapters = ENV["CENTRAL_EVENT_LOGGER_ADAPTERS"].split(/\s*,\s*/).map { |s| s.strip.downcase.to_sym }
  end

  # PostHog settings (public/event endpoints). Host defaults to PostHog EU ingest.
  config.posthog_api_host = ENV["POSTHOG_API_HOST"] if ENV["POSTHOG_API_HOST"]
  config.posthog_project_api_key = ENV["POSTHOG_PROJECT_API_KEY"] if ENV["POSTHOG_PROJECT_API_KEY"]

  # Klaviyo settings
  # Required: Klaviyo Private API Key
  # Get yours at: https://www.klaviyo.com/settings/account/api-keys
  config.klaviyo_api_key = ENV["KLAVIYO_API_KEY"] if ENV["KLAVIYO_API_KEY"]

  # if different in this app
  # config.shop_attribute_mappings = {
  #  domain: :myshopify_domain,
  #  name: :name,
  #  email: :email,
  #  owner: :shop_owner
  # }
end
