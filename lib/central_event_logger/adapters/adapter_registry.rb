# frozen_string_literal: true

module CentralEventLogger
  module Adapters
    # Registry for managing adapter registration and discovery
    class AdapterRegistry
      @adapters = {}

      class << self
        # Register an adapter class with a given name
        # @param name [Symbol] The adapter name (e.g., :posthog, :klaviyo)
        # @param adapter_class [Class] The adapter class to register
        def register(name, adapter_class)
          @adapters[name.to_sym] = adapter_class
        end

        # Get an adapter class by name
        # @param name [Symbol] The adapter name
        # @return [Class, nil] The adapter class or nil if not found
        def get(name)
          @adapters[name.to_sym]
        end

        # Check if an adapter is registered
        # @param name [Symbol] The adapter name
        # @return [Boolean] true if the adapter is registered
        def registered?(name)
          @adapters.key?(name.to_sym)
        end

        # Check if an adapter is available (registered and configured)
        # @param name [Symbol] The adapter name
        # @param config [CentralEventLogger::Configuration] The configuration object
        # @return [Boolean] true if the adapter is registered and has required configuration
        def available?(name, config)
          return false unless registered?(name)

          adapter_class = get(name)
          adapter_class.available?(config)
        end

        # Get all registered adapter names
        # @return [Array<Symbol>] Array of registered adapter names
        def all
          @adapters.keys
        end

        # Reset the registry (primarily for testing)
        def reset!
          @adapters = {}
        end
      end
    end
  end
end
