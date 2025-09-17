# frozen_string_literal: true

module CentralEventLogger
  # Configuration class for CentralEventLogger
  class Configuration
    attr_accessor :app_name, :job_queue_name, :api_base_url, :api_key, :api_secret, :shop_attribute_mappings,
                  :adapters, :posthog_api_host, :posthog_project_api_key

    def initialize
      @shop_attribute_mappings = {
        domain: :shopify_domain,
        name: :name,
        email: :email,
        owner: :shop_owner
      }
      @adapters = [:central_api]
      @posthog_api_host = ENV["POSTHOG_API_HOST"] || "https://eu.posthog.com"
      @posthog_project_api_key = ENV["POSTHOG_PROJECT_API_KEY"]
    end
  end
end
