# frozen_string_literal: true

module CentralEventLogger
  # ActiveJob class for logging events
  class EventJob < ActiveJob::Base
    queue_as { CentralEventLogger.configuration.job_queue_name }

    rescue_from(StandardError) do |exception|
      Rails.logger.error("EventJob failed: #{exception.message}")
      raise exception
    end

    def perform(event_data)
      adapters = Array(event_data[:adapters] || CentralEventLogger.configuration.adapters)
      config = CentralEventLogger.configuration

      adapters.each do |adapter_name|
        safely_deliver(adapter_name) do
          adapter = Adapters::AdapterFactory.build(adapter_name, config)
          adapter.capture_event(event_data) if adapter
        end
      end
    end

    private

    def safely_deliver(name)
      yield
    rescue StandardError => e
      Rails.error.report("CentralEventLogger adapter #{name} failed: #{e.class}: #{e.message}")
    end
  end
end
