# frozen_string_literal: true

module CentralEventLogger
  # Configuration class for CentralEventLogger
  class Configuration
    attr_accessor :app_name, :job_queue_name, :api_base_url, :api_key, :api_secret, :shop_attribute_mappings

    def initialize
      @shop_attribute_mappings = {
        domain: :shopify_domain,
        name: :name,
        email: :email,
        owner: :shop_owner
      }
    end
  end
end
