# frozen_string_literal: true

require "rails_helper"
require "central_event_logger/adapters/posthog_adapter"

RSpec.describe CentralEventLogger::Adapters::PostHogAdapter do
  let(:api_host) { "https://us.i.posthog.com" }
  let(:project_api_key) { "ph_test_key" }
  let(:client) { double("PostHog::Client", capture: true, flush: true) }

  subject(:adapter) { described_class.new(api_host, project_api_key, client: client) }

  describe ".available?" do
    let(:config) { double("config") }

    it "returns true when posthog_project_api_key is configured" do
      allow(config).to receive(:posthog_project_api_key).and_return("test_key")
      expect(described_class.available?(config)).to be true
    end

    it "returns false when posthog_project_api_key is nil" do
      allow(config).to receive(:posthog_project_api_key).and_return(nil)
      expect(described_class.available?(config)).to be false
    end
  end

  describe "#capture_event" do
    let(:timestamp) { Time.utc(2025, 1, 2, 3, 4, 5) }
    let(:event_data) do
      {
        app_name: "TestApp",
        event_name: "test_event",
        event_type: "test_type",
        event_value: "test_value",
        customer_myshopify_domain: "test-shop.myshopify.com",
        customer_info: { email: "user@example.com", name: "User" },
        payload: { extra: "data" },
        timestamp: timestamp,
        external_id: "ext-123"
      }
    end

    it "maps payload correctly and flushes" do
      expect(client).to receive(:capture).with(
        hash_including(
          distinct_id: "test-shop.myshopify.com",
          event: "test_event",
          properties: hash_including(
            app_name: "TestApp",
            event_type: "test_type",
            event_value: "test_value",
            customer_myshopify_domain: "test-shop.myshopify.com",
            customer_email: "user@example.com",
            customer_name: "User",
            extra: "data"
          ),
          timestamp: timestamp
        )
      )
      expect(client).to receive(:flush)

      expect(adapter.capture_event(event_data)).to eq(true)
    end

    it "uses external_id when domain missing and omits timestamp when not provided" do
      data = event_data.merge(customer_myshopify_domain: nil, timestamp: nil)
      expect(client).to receive(:capture) do |payload|
        expect(payload[:distinct_id]).to eq("ext-123")
        expect(payload).not_to have_key(:timestamp)
        expect(payload[:event]).to eq("test_event")
        expect(payload[:properties]).to include(app_name: "TestApp")
      end
      expect(client).to receive(:flush)

      adapter.capture_event(data)
    end

    it "handles nil customer_info without errors" do
      data = event_data.merge(customer_info: nil)
      expect(client).to receive(:capture) do |payload|
        expect(payload[:properties]).not_to include(:customer_email)
        expect(payload[:properties]).not_to include(:customer_name)
        expect(payload[:properties]).to include(app_name: "TestApp")
      end
      expect(client).to receive(:flush)

      adapter.capture_event(data)
    end
  end
end
