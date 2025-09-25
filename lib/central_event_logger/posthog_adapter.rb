# frozen_string_literal: true

require "posthog"

module CentralEventLogger
  # PostHog adapter using the official posthog-ruby client
  # Docs: https://posthog.com/docs/libraries/ruby
  class PostHogAdapter
    def initialize(api_host, project_api_key, client: nil)
      @client = client || PostHog::Client.new({
                                                api_key: project_api_key,
                                                host: api_host,
                                                on_error: proc { |status, msg|
                                                  if defined?(Rails) && Rails.respond_to?(:error)
                                                    Rails.error.report("PostHog error #{status}: #{msg}")
                                                  end
                                                }
                                              })
    end

    # event_data keys come from CentralEventLogger.log_event
    def capture_event(event_data)
      distinct_id = event_data[:customer_myshopify_domain] || event_data[:external_id] || event_data[:customer_info]&.dig(:id) || "unknown"

      properties = {
        app_name: event_data[:app_name],
        event_type: event_data[:event_type],
        event_value: event_data[:event_value],
        customer_myshopify_domain: event_data[:customer_myshopify_domain],
        customer_info: event_data[:customer_info],
        payload: event_data[:payload]
      }.compact

      payload = {
        distinct_id: distinct_id,
        event: event_data[:event_name],
        properties: properties
      }
      if event_data[:timestamp]
        ts = event_data[:timestamp]
        payload[:timestamp] = ts.is_a?(Time) ? ts : Time.zone.parse(ts)
      end

      @client.capture(payload)
      @client.flush
      true
    end
  end
end
