# frozen_string_literal: true

require "active_record"
require "active_job"
require_relative "central_event_logger/configuration"
require "central_event_logger/railtie" if defined?(Rails)

# CentralEventLogger is a library for logging events to a central database.
module CentralEventLogger
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.log_event(event_name:, event_type:, customer_myshopify_domain:, customer_info: {},
                     event_value: nil, payload: {}, timestamp: Time.now, app_name: nil, external_id: nil)
    # Skip logging if API base URL is not configured
    return if ENV["CENTRAL_EVENT_LOGGER_API_BASE_URL"].nil?

    # Validate required parameters
    raise ArgumentError, "event_name is required" unless event_name
    raise ArgumentError, "event_type is required" unless event_type
    raise ArgumentError, "customer_myshopify_domain is required" unless customer_myshopify_domain

    # Use default app_id from configuration if not provided
    app_name ||= configuration.app_name
    raise ArgumentError, "app_name is required" unless app_name

    # Enqueue the event for asynchronous processing
    EventJob.perform_later(
      app_name: ,
      event_name: ,
      event_type: ,
      event_value: ,
      customer_myshopify_domain: ,
      customer_info: ,
      payload: ,
      timestamp:,
      external_id:
    )
  end
end
