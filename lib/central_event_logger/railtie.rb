# frozen_string_literal: true

module CentralEventLogger
  # Railtie for CentralEventLogger
  class Railtie < Rails::Railtie
    initializer "central_event_logger.configure_rails_initialization" do
      ActiveSupport.on_load(:active_record) do
        require_relative "configuration"
        require_relative "event_job"
        require_relative "models/reporting_base"
        require_relative "models/app"
        require_relative "models/customer"
        require_relative "models/event"
        require_relative "event_types"
        require_relative "trackable"
        require_relative "../../config/initializers/central_event_logger"
      end
    end
  end
end
