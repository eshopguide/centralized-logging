# frozen_string_literal: true

require "rails_helper"
require "central_event_logger"
require "central_event_logger/event_job"

RSpec.describe CentralEventLogger do
  before do
    CentralEventLogger.configure do |config|
      config.app_name = "test_app_name"
      # Ensure at least one usable adapter so log_event enqueues
      config.adapters = [:central_api]
      allow(config).to receive(:api_base_url).and_return("https://api.example.com")
    end
  end

  it "enqueues an event job with correct parameters" do
    timestamp = Time.now
    allow(Time).to receive(:now).and_return(timestamp)

    expect(CentralEventLogger::EventJob).to receive(:perform_later).with(
      app_name: "test_app_name",
      event_name: "test_event",
      event_type: "test_type",
      event_value: "test_value",
      customer_myshopify_domain: "test.myshopify.com",
      customer_info: {
        email: "test@example.com",
        name: "Test User",
        shop_owner: "Test Owner"
      },
      external_id: "12345",
      payload: { extra: "data" },
      timestamp: timestamp
    )

    CentralEventLogger.log_event(
      event_name: "test_event",
      event_type: "test_type",
      event_value: "test_value",
      customer_myshopify_domain: "test.myshopify.com",
      customer_info: {
        email: "test@example.com",
        name: "Test User",
        shop_owner: "Test Owner"
      },
      external_id: "12345",
      payload: { extra: "data" }
    )
  end

  it "raises an error if app_name is not configured" do
    CentralEventLogger.configuration.app_name = nil
    expect do
      CentralEventLogger.log_event(
        event_name: "test_event",
        event_type: "test_type",
        customer_myshopify_domain: "test.myshopify.com"
      )
    end.to raise_error(ArgumentError, "app_name is required")
  end

  it "raises an error if required parameters are missing" do
    expect do
      CentralEventLogger.log_event(
        event_type: "test_type",
        customer_myshopify_domain: "test.myshopify.com"
      )
    end.to raise_error(ArgumentError, "missing keyword: :event_name")

    expect do
      CentralEventLogger.log_event(
        event_name: "test_event",
        customer_myshopify_domain: "test.myshopify.com"
      )
    end.to raise_error(ArgumentError, "missing keyword: :event_type")

    expect do
      CentralEventLogger.log_event(
        event_name: "test_event",
        event_type: "test_type"
      )
    end.to raise_error(ArgumentError, "missing keyword: :customer_myshopify_domain")
  end

  context "with customer_info" do
    it "accepts valid customer_info parameters" do
      expect do
        CentralEventLogger.log_event(
          event_name: "test_event",
          event_type: "test_type",
          customer_myshopify_domain: "test.myshopify.com",
          customer_info: {
            email: "test@example.com",
            name: "Test User",
            shop_owner: "Test Owner"
          }
        )
      end.not_to raise_error
    end
  end
end
