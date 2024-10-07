# frozen_string_literal: true

require "active_record"
require "active_job"
require "central_event_logger/configuration"
require "central_event_logger/event_job"
require "central_event_logger/models/app"
require "central_event_logger/models/customer"
require "central_event_logger/models/event"

# CentralEventLogger is a library for logging events to a central database.
module CentralEventLogger
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)

    # Establish connection to the reporting database
    ActiveRecord::Base.establish_connection(configuration.reporting_database)
  end

  def self.log_event(event_name:, event_type:, event_value:, customer_id:, payload: {}, timestamp: Time.now, app_id: nil)
    # Validate required parameters
    raise ArgumentError, "event_name is required" unless event_name
    raise ArgumentError, "event_type is required" unless event_type
    raise ArgumentError, "customer_id is required" unless customer_id

    # Use default app_id from configuration if not provided
    app_id ||= configuration.app_id
    raise ArgumentError, "app_id is required" unless app_id

    # Enqueue the event for asynchronous processing
    EventJob.perform_later(
      app_id: app_id,
      event_name: event_name,
      event_type: event_type,
      event_value: event_value,
      customer_id: customer_id,
      payload: payload,
      timestamp: timestamp
    )
  end
end
