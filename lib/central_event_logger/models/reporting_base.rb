module CentralEventLogger
  module Models
    # base class for reporting database models
    class ReportingBase < ActiveRecord::Base
      self.abstract_class = true
      establish_connection :reporting
    end
  end
end
