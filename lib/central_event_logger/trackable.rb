# frozen_string_literal: true

module CentralEventLogger
  # This module is responsible for tracking changes in the model and pushing them to the reporting database
  module Trackable
    extend ActiveSupport::Concern

    included do
      after_update :log_changes
    end

    private

    def log_changes
      excluded_columns = %w[updated_at created_at id]

      saved_changes.each do |attribute, changes|
        next if excluded_columns.include?(attribute)

        CentralEventLogger.log_event(
          event_name: attribute,
          event_type: CentralEventLogger::EventTypes::SETTINGS_CHANGE,
          customer_myshopify_domain: self&.shop&.shopify_domain,
          event_value: changes.last,
          payload: { from: changes.first, to: changes.last },
          app_name: CentralEventLogger.configuration.app_name
        )
      end
    end
  end
end
