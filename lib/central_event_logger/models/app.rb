module CentralEventLogger
  module Models
    class App < ActiveRecord::Base
      self.table_name = 'apps'

      has_many :events
    end
  end
end
