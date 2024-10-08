# frozen_string_literal: true
require "rails_helper"
require "central_event_logger"

RSpec.describe CentralEventLogger do
  before do
    CentralEventLogger.configure do |config|
      config.reporting_database = ENV.fetch("REPORTING_DATABASE_URL", "test_database_url")
      config.app_id = "test_app_id"
    end
  end

  it "enqueues an event job with correct parameters" do
    expect(CentralEventLogger::EventJob).to receive(:perform_later).with(
      hash_including(
        app_id: "test_app_id",
        event_name: "test_event",
        event_type: "test_type",
        customer_id: 1
      )
    )

    CentralEventLogger.log_event(
      event_name: "test_event",
      event_type: "test_type",
      event_value: "test_value",
      customer_id: 1
    )
  end

  it "raises an error if app_id is not configured" do
    CentralEventLogger.configuration.app_id = nil
    expect {
      CentralEventLogger.log_event(
        event_name: "test_event",
        event_type: "test_type",
        customer_id: 1
      )
    }.to raise_error(ArgumentError, "app_id is required")
  end
end
