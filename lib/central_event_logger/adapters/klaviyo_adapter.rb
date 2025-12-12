# frozen_string_literal: true
require "klaviyo-api-sdk"
require_relative "base_adapter"

module CentralEventLogger
  module Adapters
    # Klaviyo adapter using the official klaviyo-api-sdk gem
    # Docs: https://github.com/klaviyo/klaviyo-api-ruby
    class KlaviyoAdapter < BaseAdapter
      def initialize(api_key, client: nil)
        @api_key = api_key
        # Configure Klaviyo API globally
        KlaviyoAPI.configure do |config|
          config.api_key["Klaviyo-API-Key"] = @api_key
        end
        @client = client
      end

      # Check if Klaviyo adapter is available
      # @param config [CentralEventLogger::Configuration] The configuration object
      # @return [Boolean] true if Klaviyo API key is configured
      def self.available?(config)
        !config.klaviyo_api_key.nil?
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

        # Build profile properties from customer_info
        profile_properties = build_profile_properties(event_data[:customer_info])

        # Build event properties
        event_properties = {
          app_name: event_data[:app_name],
          event_type: event_data[:event_type],
          event_value: event_data[:event_value],
          customer_myshopify_domain: event_data[:customer_myshopify_domain]
        }.compact.merge(event_data[:payload] || {})

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
                    name: event_data[:event_name]
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

      # Build profile properties from customer_info hash
      # Maps common fields and includes custom properties
      def build_profile_properties(customer_info)
        return {} unless customer_info.is_a?(Hash)

        properties = {}

        # Map standard Klaviyo profile fields
        properties[:first_name] = customer_info[:first_name] if customer_info[:first_name]
        properties[:last_name] = customer_info[:last_name] if customer_info[:last_name]
        properties[:phone_number] = customer_info[:phone] if customer_info[:phone]
        properties[:external_id] = customer_info[:id] if customer_info[:id]

        # Add any other custom properties
        customer_info.each do |key, value|
          next if %i[email first_name last_name phone id].include?(key)

          properties[key] = value
        end

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
