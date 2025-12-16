# frozen_string_literal: true

require "klaviyo-api-sdk"
require_relative "base_adapter"

module CentralEventLogger
  module Adapters
    # Klaviyo adapter using the official klaviyo-api-sdk gem
    # Docs: https://github.com/klaviyo/klaviyo-api-ruby
    class KlaviyoAdapter < BaseAdapter
      EVENT_NAME_MAPPING = {
        "app_installed" => "Install",
        "app_uninstalled" => "Uninstall",
        "user_acquisition" => "Activated",
        "connection_lost" => "Connection Lost"
      }.freeze

      def initialize(api_key, client: nil)
        @api_key = api_key
        # Configure Klaviyo API globally
        KlaviyoAPI.configure do |config|
          config.api_key["Klaviyo-API-Key"] = @api_key
          config.api_key_prefix["Klaviyo-API-Key"] = "Klaviyo-API-Key"
          config.verify_ssl = false if Rails.env.development?
          config.verify_ssl_host = false if Rails.env.development?
        end
        @client = client
      end

      # Check if Klaviyo adapter is available
      # @param config [CentralEventLogger::Configuration] The configuration object
      # @return [Boolean] true if Klaviyo API key is configured
      def self.available?(config)
        !config.klaviyo_api_key.nil?
      end

      # Factory method to create an adapter instance from configuration
      # @param config [CentralEventLogger::Configuration] The configuration object
      # @return [KlaviyoAdapter] An instance of the adapter
      def self.from_config(config)
        new(config.klaviyo_api_key)
      end

      # Capture an event and send it to Klaviyo
      # @param event_data [Hash] The event data to capture
      # @return [Boolean] true if the event was successfully captured
      def capture_event(event_data)
        # Extract email from customer_info - required for Klaviyo
        email = event_data[:customer_info]&.dig(:email)

        unless email
          if defined?(Rails)
            Rails.logger.warn("KlaviyoAdapter: Missing email in customer_info, skipping event #{event_data[:event_name]}")
          end
          return false
        end

        # Map internal names to display names
        metric_name = map_event_name(event_data[:event_name])

        # Build profile properties from customer_info
        profile_properties = build_profile_properties(event_data[:customer_info])

        # Build base properties required for all events
        base_properties = {
          app_name: event_data[:app_name],
          changed_at: format_timestamp(event_data[:timestamp]),
          initiated_by: "user",
          shop_domain: event_data[:customer_myshopify_domain]
        }

        # Merge payload, filtering out implementation-specific fields if needed
        # and adding event-specific properties
        payload = event_data[:payload] || {}

        # Filter payload based on metric name for specific scenarios if needed
        filtered_payload = case metric_name
                           when "Activated", "Uninstall", "Connection Lost"
                             payload.slice(:app_plan, :plan_value)
                           else
                             # For Install and others, we might not want extra payload fields unless specified
                             # But based on example 1, Install just has base properties
                             {}
                           end

        event_properties = base_properties.merge(filtered_payload)

        # Build the event request body according to Klaviyo API spec
        body = {
          data: {
            type: "event",
            attributes: {
              profile: {
                data: {
                  type: "profile",
                  attributes: {
                    email: email,
                    **profile_properties
                  }
                }
              },
              metric: {
                data: {
                  type: "metric",
                  attributes: {
                    name: metric_name
                  }
                }
              },
              properties: event_properties,
              time: format_timestamp(event_data[:timestamp])
            }
          }
        }

        # Use the client if provided (for testing), otherwise use the SDK
        if @client
          @client.create_event(body)
        else
          KlaviyoAPI::Events.create_event(body)
        end

        true
      rescue StandardError => e
        Rails.error.report("KlaviyoAdapter error: #{e.class}: #{e.message}") if defined?(Rails)
        false
      end

      private

      def map_event_name(internal_name)
        EVENT_NAME_MAPPING[internal_name] || internal_name
      end

      def map_app_name(internal_name)
        APP_NAME_MAPPING[internal_name] || internal_name
      end

      # Build profile properties from customer_info hash
      # Maps common fields and includes custom properties
      def build_profile_properties(customer_info)
        return {} unless customer_info.is_a?(Hash)

        properties = {}

        # Handle splitting owner/shop_owner if first/last name missing
        first_name = customer_info[:first_name]
        last_name = customer_info[:last_name]

        if (first_name.nil? || last_name.nil?) && (owner = customer_info[:owner] || customer_info[:shop_owner])
          names = owner.split(" ")
          first_name ||= names.first
          last_name ||= names.last if names.length > 1
        end

        # Map standard Klaviyo profile fields
        properties[:first_name] = first_name if first_name
        properties[:last_name] = last_name if last_name
        properties[:phone_number] = customer_info[:phone] if customer_info[:phone]
        properties[:external_id] = customer_info[:id] if customer_info[:id]

        properties.compact
      end

      # Format timestamp for Klaviyo API (ISO 8601)
      def format_timestamp(timestamp)
        return Time.now.utc.iso8601 unless timestamp

        ts = timestamp.is_a?(Time) ? timestamp : Time.zone.parse(timestamp.to_s)
        ts.utc.iso8601
      end
    end
  end
end

# Register the adapter
CentralEventLogger::Adapters::AdapterRegistry.register(:klaviyo, CentralEventLogger::Adapters::KlaviyoAdapter)
