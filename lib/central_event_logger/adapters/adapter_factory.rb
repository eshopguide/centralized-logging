# frozen_string_literal: true

module CentralEventLogger
  module Adapters
    # Factory for creating adapter instances with proper configuration
    class AdapterFactory
      # Build an adapter instance
      # @param adapter_name [Symbol] The name of the adapter to build
      # @param config [CentralEventLogger::Configuration] The configuration object
      # @return [BaseAdapter, nil] The configured adapter instance or nil if unavailable
      def self.build(adapter_name, config)
        adapter_class = AdapterRegistry.get(adapter_name)

        unless adapter_class
          Rails.logger.warn("Unknown CentralEventLogger adapter: #{adapter_name}") if defined?(Rails)
          return nil
        end

        return nil unless adapter_class.available?(config)

        case adapter_name
        when :central_api
          require_relative "../api_client"
          ApiClient.new(config.api_base_url, config.api_key, config.api_secret)
        when :posthog
          require_relative "posthog_adapter"
          PostHogAdapter.new(config.posthog_api_host, config.posthog_project_api_key)
        when :klaviyo
          require_relative "klaviyo_adapter"
          KlaviyoAdapter.new(config.klaviyo_api_key)
        else
          Rails.logger.warn("No factory method defined for adapter: #{adapter_name}") if defined?(Rails)
          nil
        end
      end
    end
  end
end
