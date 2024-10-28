# frozen_string_literal: true

module CentralEventLogger
  # This module is responsible for tracking changes in the model and pushing them to the reporting database
  module Trackable
    extend ActiveSupport::Concern

    DEFAULT_EXCLUDED_COLUMNS = %w[updated_at created_at id shop_id].freeze

    included do
      # Default configurations
      class_attribute :track_creates, default: false
      class_attribute :reporting_excluded_columns
      class_attribute :prefix_events, default: false

      # Set the default value with the union
      self.reporting_excluded_columns = [] | DEFAULT_EXCLUDED_COLUMNS

      after_update :log_changes
      after_create :log_changes, if: :track_creates
    end

    private

    def log_changes
      mappings = CentralEventLogger.configuration.shop_attribute_mappings

      saved_changes.each do |attribute, changes|
        next if reporting_excluded_columns.include?(attribute)

        event_name = prefix_events ? "#{self.class.table_name}.#{attribute}" : attribute

        CentralEventLogger.log_event(
          event_name: event_name,
          event_type: CentralEventLogger::EventTypes::SETTINGS_CHANGE,
          customer_myshopify_domain: self&.shop&.public_send(mappings[:domain]),
          customer_info: {
            name: self&.shop&.public_send(mappings[:name]),
            email: self&.shop&.public_send(mappings[:email]),
            owner: self&.shop&.public_send(mappings[:owner])
          },
          event_value: changes.last,
          payload: { from: changes.first, to: changes.last },
          app_name: CentralEventLogger.configuration.app_name
        )
      end
    end
  end
end
