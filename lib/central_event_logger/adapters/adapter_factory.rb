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
        load_adapter(adapter_name)
        adapter_class = AdapterRegistry.get(adapter_name)

        unless adapter_class
          Rails.error.report("Unknown CentralEventLogger adapter: #{adapter_name}") if defined?(Rails)
          return nil
        end

        return nil unless adapter_class.available?(config)

        instance = adapter_class.from_config(config)
        if instance.respond_to?(:event_whitelist=)
          instance.event_whitelist = config.adapter_event_whitelists[adapter_name]
        end
        instance
      end

      # Load the adapter file based on the adapter name
      # @param adapter_name [Symbol] The name of the adapter
      def self.load_adapter(adapter_name)
        require_relative "#{adapter_name}_adapter"
      rescue LoadError => e
        Rails.error.report("Could not load adapter #{adapter_name}: #{e.message}") if defined?(Rails)
      end
    end
  end
end
