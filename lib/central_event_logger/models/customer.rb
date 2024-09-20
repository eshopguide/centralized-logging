module CentralEventLogger
  module Models
    class Customer < ActiveRecord::Base
      self.table_name = 'customers'

      has_many :events
    end
  end
end
