# frozen_string_literal: true

module CentralEventLogger
  # ActiveJob class for logging events
  class EventJob < ActiveJob::Base
    queue_as { CentralEventLogger.configuration.job_queue_name }

    def perform(event_data)

      # Create or find the customer and app records
      customer = Models::Customer.find_or_create_by(myshopify_domain: event_data[:customer_myshopify_domain])
      app = Models::App.find_or_create_by(name: event_data[:app_name])

      # Create the event record
      Models::Event.create!(
        app: app,
        customer: customer,
        event_name: event_data[:event_name],
        event_type: event_data[:event_type],
        event_value: event_data[:event_value],
        payload: event_data[:payload],
        timestamp: event_data[:timestamp]
      )
    rescue => e
      # Handle exceptions (e.g., log the error, retry logic)
      Rails.logger.error("EventJob failed: #{e.message}")
      raise e
    end
  end
end
