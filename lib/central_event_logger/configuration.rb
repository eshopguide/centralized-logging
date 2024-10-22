# frozen_string_literal: true

module CentralEventLogger
  # Configuration class for CentralEventLogger
  class Configuration
    attr_accessor :app_name, :job_queue_name
    attr_reader :api_base_url, :api_key, :api_secret

    def initialize
      @job_queue_name = ENV["CENTRAL_EVENT_LOGGER_QUEUE"] || "default"
      @api_base_url = ENV["CENTRAL_EVENT_LOGGER_API_BASE_URL"]
      @api_key = ENV["CENTRAL_EVENT_LOGGER_API_KEY"]
      @api_secret = ENV["CENTRAL_EVENT_LOGGER_API_SECRET"]
    end

    def api_base_url=(value)
      raise ArgumentError, "API base URL should be set using CENTRAL_EVENT_LOGGER_API_BASE_URL environment variable"
    end

    def api_key=(value)
      raise ArgumentError, "API key should be set using CENTRAL_EVENT_LOGGER_API_KEY environment variable"
    end

    def api_secret=(value)
      raise ArgumentError, "API secret should be set using CENTRAL_EVENT_LOGGER_API_SECRET environment variable"
    end
  end
end
