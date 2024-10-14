# frozen_string_literal: true

module CentralEventLogger
  module Models
    # Describes an event that occurred in an application
    class Event < ReportingBase
      self.table_name = "events"

      belongs_to :app
      belongs_to :customer

      validates :event_name, presence: true
      validates :event_type, presence: true
      validates :timestamp,  presence: true
    end
  end
end
