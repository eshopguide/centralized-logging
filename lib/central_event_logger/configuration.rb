# frozen_string_literal: true

module CentralEventLogger
  class Configuration
    attr_accessor :reporting_database, :app_id, :job_queue_name

    def initialize
      @job_queue_name = :default
    end
  end
end