# frozen_string_literal: true

module CentralEventLogger
  module Adapters
    # Base class for all event logging adapters
    # Provides common interface that all adapters must implement
    class BaseAdapter
      # Check if the adapter is available based on configuration
      # @param config [CentralEventLogger::Configuration] The configuration object
      # @return [Boolean] true if the adapter has all required configuration
      def self.available?(config)
        raise NotImplementedError, "#{name} must implement .available?(config)"
      end

      # Capture an event and send it to the adapter's destination
      # @param event_data [Hash] The event data to capture
      # @return [Boolean] true if the event was successfully captured
      def capture_event(event_data)
        raise NotImplementedError, "#{self.class.name} must implement #capture_event(event_data)"
      end

      # Factory method to create an adapter instance from configuration
      # @param config [CentralEventLogger::Configuration] The configuration object
      # @return [BaseAdapter] An instance of the adapter
      def self.from_config(config)
        raise NotImplementedError, "#{name} must implement .from_config(config)"
      end
    end
  end
end
