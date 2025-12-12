# frozen_string_literal: true

require "posthog"
require_relative "base_adapter"

module CentralEventLogger
  module Adapters
    # PostHog adapter using the official posthog-ruby client
    # Docs: https://posthog.com/docs/libraries/ruby
    class PostHogAdapter < BaseAdapter
      def initialize(api_host, project_api_key, client: nil)
        @client = client || PostHog::Client.new({
                                                  api_key: project_api_key,
                                                  host: api_host,
                                                  on_error: proc { |status, msg|
                                                    if defined?(Rails) && Rails.respond_to?(:error)
                                                      Rails.error.report("PostHog error #{status}: #{msg}")
                                                    end
                                                  }
                                                })
      end

      # Check if PostHog adapter is available
      # @param config [CentralEventLogger::Configuration] The configuration object
      # @return [Boolean] true if PostHog API key is configured
      def self.available?(config)
        !config.posthog_project_api_key.nil?
      end

      # Factory method to create an adapter instance from configuration
      # @param config [CentralEventLogger::Configuration] The configuration object
      # @return [PostHogAdapter] An instance of the adapter
      def self.from_config(config)
        new(config.posthog_api_host, config.posthog_project_api_key)
      end

      # event_data keys come from CentralEventLogger.log_event
      def capture_event(event_data)
        distinct_id = event_data[:customer_myshopify_domain] || event_data[:external_id] || event_data[:customer_info]&.dig(:id) || "unknown"

        # Spread the customer_info hash into properties with "customer_" prefix
        customer_info_prefixed = {}
        if event_data[:customer_info].is_a?(Hash)
          event_data[:customer_info].each do |k, v|
            customer_info_prefixed[:"customer_#{k}"] = v
          end
        end

        properties = {
          app_name: event_data[:app_name],
          event_type: event_data[:event_type],
          event_value: event_data[:event_value],
          customer_myshopify_domain: event_data[:customer_myshopify_domain],
          customer_info: event_data[:customer_info],
          **event_data[:payload],
          **customer_info_prefixed
        }.compact

        payload = {
          distinct_id: distinct_id,
          event: event_data[:event_name],
          properties: properties
        }
        if event_data[:timestamp]
          ts = event_data[:timestamp]
          payload[:timestamp] = ts.is_a?(Time) ? ts : Time.zone.parse(ts)
        end

        @client.capture(payload)
        @client.flush
        true
      end
    end
  end
end

# Register the adapter
CentralEventLogger::Adapters::AdapterRegistry.register(:posthog, CentralEventLogger::Adapters::PostHogAdapter)
