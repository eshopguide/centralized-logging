# frozen_string_literal: true

module CentralEventLogger
  # Configuration class for CentralEventLogger
  class Configuration
    attr_accessor :app_name, :job_queue_name

    def initialize
      @job_queue_name = :default
    end
  end
end
