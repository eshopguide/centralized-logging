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
      api_client = ApiClient.new(CentralEventLogger.configuration.api_base_url,
                                 CentralEventLogger.configuration.api_key,
                                 CentralEventLogger.configuration.api_secret)

      api_client.create_event(event_data)
    end
  end
end
