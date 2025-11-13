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
      timestamp: timestamp,
      adapters: [:central_api]
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

  context "with per-call adapters override" do
    it "enqueues with provided adapters only" do
      timestamp = Time.now
      allow(Time).to receive(:now).and_return(timestamp)

      expect(CentralEventLogger::EventJob).to receive(:perform_later).with(
        hash_including(adapters: [:posthog])
      )

      # Configure a usable PostHog env
      CentralEventLogger.configuration.posthog_project_api_key = "ph_test_key"

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
        adapters: [:posthog]
      )
    end
  end

  describe ".has_usable_adapter?" do
    let(:config) { CentralEventLogger.configuration }

    context "with central_api adapter" do
      it "returns true when api_base_url is configured" do
        config.adapters = [:central_api]
        config.api_base_url = "https://api.example.com"

        expect(CentralEventLogger.has_usable_adapter?).to be true
      end

      it "returns false when api_base_url is nil" do
        config.adapters = [:central_api]
        config.api_base_url = nil

        expect(CentralEventLogger.has_usable_adapter?).to be false
      end
    end

    context "with posthog adapter" do
      it "returns true when posthog_project_api_key is configured" do
        config.adapters = [:posthog]
        config.posthog_project_api_key = "ph_test_key"

        expect(CentralEventLogger.has_usable_adapter?).to be true
      end

      it "returns false when posthog_project_api_key is nil" do
        config.adapters = [:posthog]
        config.posthog_project_api_key = nil

        expect(CentralEventLogger.has_usable_adapter?).to be false
      end
    end

    context "with klaviyo adapter" do
      it "returns true when klaviyo_api_key is configured" do
        config.adapters = [:klaviyo]
        config.klaviyo_api_key = "klaviyo_test_key"

        expect(CentralEventLogger.has_usable_adapter?).to be true
      end

      it "returns false when klaviyo_api_key is nil" do
        config.adapters = [:klaviyo]
        config.klaviyo_api_key = nil

        expect(CentralEventLogger.has_usable_adapter?).to be false
      end
    end

    context "with multiple adapters" do
      it "returns true if at least one adapter is usable" do
        config.adapters = [:central_api, :posthog, :klaviyo]
        config.api_base_url = nil
        config.posthog_project_api_key = "ph_test_key"
        config.klaviyo_api_key = nil

        expect(CentralEventLogger.has_usable_adapter?).to be true
      end

      it "returns false if no adapters are usable" do
        config.adapters = [:central_api, :posthog, :klaviyo]
        config.api_base_url = nil
        config.posthog_project_api_key = nil
        config.klaviyo_api_key = nil

        expect(CentralEventLogger.has_usable_adapter?).to be false
      end
    end

    context "with explicit adapters parameter" do
      it "checks only the provided adapters" do
        config.adapters = [:central_api]
        config.api_base_url = "https://api.example.com"
        config.posthog_project_api_key = nil

        expect(CentralEventLogger.has_usable_adapter?([:posthog])).to be false
        expect(CentralEventLogger.has_usable_adapter?([:central_api])).to be true
      end
    end
  end
end
