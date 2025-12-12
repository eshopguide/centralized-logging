# frozen_string_literal: true

module CentralEventLogger
  # Railtie for CentralEventLogger
  class Railtie < Rails::Railtie
    initializer "central_event_logger.configure_rails_initialization" do
      require_relative "configuration"
      ActiveSupport.on_load(:active_record) do
        require_relative "adapters/central_api_adapter"
        require_relative "event_job"
        require_relative "event_types"
        require_relative "trackable"
        require_relative "../../config/initializers/central_event_logger"
      end
    end
  end
end
