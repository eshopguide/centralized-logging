module CentralEventLogger
  module Models
    class Event < ActiveRecord::Base
      self.table_name = 'events'

      belongs_to :app
      belongs_to :customer

      validates :event_name, presence: true
      validates :event_type, presence: true
      validates :timestamp,  presence: true
    end
  end
end
