# frozen_string_literal: true

require "net/http"
require "json"

module CentralEventLogger
  # This class is responsible for making API requests to the central event logging service
  class ApiClient
    def initialize(base_url, api_key, api_secret)
      @base_url = base_url
      @api_key = api_key
      @api_secret = api_secret
    end

    def create_event(event_data)
      uri = URI("#{@base_url}/api/v1/events")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["X-API-Key"] = @api_key
      request["X-API-Secret"] = @api_secret
      request.body = { event: event_data }.to_json

      response = http.request(request)

      raise "API request failed: #{response.code} - #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end
end
