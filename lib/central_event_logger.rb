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
                     event_value: nil, payload: {}, timestamp: Time.now, app_name: nil, external_id: nil,
                     adapters: nil)
    # Skip logging if nothing is configured
    return if configuration.nil?

    # Only enqueue if at least one configured adapter is usable
    effective_adapters = Array(adapters || configuration.adapters)
    return unless has_usable_adapter?(effective_adapters)

    # Validate required parameters
    raise ArgumentError, "event_name is required" unless event_name
    raise ArgumentError, "event_type is required" unless event_type
    raise ArgumentError, "customer_myshopify_domain is required" unless customer_myshopify_domain

    # Use default app_id from configuration if not provided
    app_name ||= configuration.app_name
    raise ArgumentError, "app_name is required" unless app_name

    # Enqueue the event for asynchronous processing
    EventJob.perform_later(**{
      app_name: app_name,
      event_name: event_name,
      event_type: event_type,
      event_value: event_value,
      customer_myshopify_domain: customer_myshopify_domain,
      customer_info: customer_info,
      payload: payload,
      timestamp: timestamp,
      external_id: external_id,
      adapters: effective_adapters
    }.compact)
  end

  # Helper method to check if at least one adapter is usable
  def self.has_usable_adapter?(adapters = nil)
    list = Array(adapters || configuration.adapters)
    list.any? do |adapter|
      case adapter
      when :central_api
        !configuration.api_base_url.nil?
      when :posthog
        !configuration.posthog_project_api_key.nil?
      else
        false
      end
    end
  end
end
