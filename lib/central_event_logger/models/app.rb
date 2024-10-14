module CentralEventLogger
  module Models
    class App < ReportingBase
      self.table_name = 'apps'

      has_many :events
    end
  end
end
