module CentralEventLogger
  module Models
    class Customer < ReportingBase
      self.table_name = 'customers'

      has_many :events
    end
  end
end
