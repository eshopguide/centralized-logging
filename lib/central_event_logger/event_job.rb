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
      adapters = Array(CentralEventLogger.configuration.adapters)

      adapters.each do |adapter|
        case adapter
        when :central_api
          if CentralEventLogger.configuration.api_base_url
            client = ApiClient.new(CentralEventLogger.configuration.api_base_url,
                                   CentralEventLogger.configuration.api_key,
                                   CentralEventLogger.configuration.api_secret)
            safely_deliver("central_api") { client.create_event(event_data) }
          end
        when :posthog
          if CentralEventLogger.configuration.posthog_project_api_key
            require_relative "posthog_adapter"
            client = PostHogAdapter.new(
              CentralEventLogger.configuration.posthog_api_host,
              CentralEventLogger.configuration.posthog_project_api_key
            )
            safely_deliver("posthog") { client.capture_event(event_data) }
          end
        else
          Rails.logger.warn("Unknown CentralEventLogger adapter: #{adapter}")
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
