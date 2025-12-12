# frozen_string_literal: true

require "rails_helper"
require "central_event_logger/adapters/klaviyo_adapter"

RSpec.describe CentralEventLogger::Adapters::KlaviyoAdapter do
  let(:api_key) { "klaviyo_test_key" }
  let(:client) { double("KlaviyoAPI::Events", create_event: true) }

  subject(:adapter) { described_class.new(api_key, client: client) }

  describe ".available?" do
    let(:config) { double("config") }

    it "returns true when klaviyo_api_key is configured" do
      allow(config).to receive(:klaviyo_api_key).and_return("test_key")
      expect(described_class.available?(config)).to be true
    end

    it "returns false when klaviyo_api_key is nil" do
      allow(config).to receive(:klaviyo_api_key).and_return(nil)
      expect(described_class.available?(config)).to be false
    end
  end

  describe "#capture_event" do
    let(:timestamp) { Time.utc(2025, 1, 2, 3, 4, 5) }
    let(:event_data) do
      {
        app_name: "TestApp",
        event_name: "Purchase Completed",
        event_type: "purchase",
        event_value: 99.99,
        customer_myshopify_domain: "test-shop.myshopify.com",
        customer_info: {
          email: "user@example.com",
          first_name: "John",
          last_name: "Doe",
          phone: "+1234567890",
          id: "customer_123"
        },
        payload: { product_id: "prod_456", quantity: 2 },
        timestamp: timestamp
      }
    end

    it "sends event to Klaviyo with correct format" do
      expect(client).to receive(:create_event) do |body|
        data = body[:data]
        attributes = data[:attributes]

        # Check profile data
        profile_attributes = attributes[:profile][:data][:attributes]
        expect(profile_attributes[:email]).to eq("user@example.com")
        expect(profile_attributes[:first_name]).to eq("John")
        expect(profile_attributes[:last_name]).to eq("Doe")
        expect(profile_attributes[:phone_number]).to eq("+1234567890")
        expect(profile_attributes[:external_id]).to eq("customer_123")

        # Check metric data
        metric_attributes = attributes[:metric][:data][:attributes]
        expect(metric_attributes[:name]).to eq("Purchase Completed")

        # Check event properties
        properties = attributes[:properties]
        expect(properties[:app_name]).to eq("TestApp")
        expect(properties[:event_type]).to eq("purchase")
        expect(properties[:event_value]).to eq(99.99)
        expect(properties[:customer_myshopify_domain]).to eq("test-shop.myshopify.com")
        expect(properties[:product_id]).to eq("prod_456")
        expect(properties[:quantity]).to eq(2)

        # Check timestamp
        expect(attributes[:time]).to eq(timestamp.utc.iso8601)
      end

      result = adapter.capture_event(event_data)
      expect(result).to be true
    end

    it "returns false and logs warning when email is missing" do
      data = event_data.merge(customer_info: { first_name: "John" })

      expect(Rails.logger).to receive(:warn).with(/Missing email/)
      result = adapter.capture_event(data)
      expect(result).to be false
    end

    it "returns false when customer_info is nil" do
      data = event_data.merge(customer_info: nil)

      expect(Rails.logger).to receive(:warn).with(/Missing email/)
      result = adapter.capture_event(data)
      expect(result).to be false
    end

    it "uses current time when timestamp is not provided" do
      data = event_data.merge(timestamp: nil)

      expect(client).to receive(:create_event) do |body|
        time_attr = body[:data][:attributes][:time]
        expect(time_attr).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
      end

      adapter.capture_event(data)
    end

    it "handles exceptions and returns false" do
      allow(client).to receive(:create_event).and_raise(StandardError.new("API Error"))
      expect(Rails.error).to receive(:report).with(/KlaviyoAdapter error/)

      result = adapter.capture_event(event_data)
      expect(result).to be false
    end

    it "includes custom customer_info fields in profile properties" do
      data = event_data.merge(
        customer_info: {
          email: "user@example.com",
          custom_field: "custom_value",
          subscription_tier: "premium"
        }
      )

      expect(client).to receive(:create_event) do |body|
        profile_attributes = body[:data][:attributes][:profile][:data][:attributes]
        expect(profile_attributes[:custom_field]).to eq("custom_value")
        expect(profile_attributes[:subscription_tier]).to eq("premium")
      end

      adapter.capture_event(data)
    end
  end

  context "specific event scenarios" do
    let(:timestamp) { Time.utc(2025, 1, 1, 12, 0, 0) }
    let(:common_customer_info) do
      {
        email: "sarah.mason@test.com",
        first_name: "Sarah",
        last_name: "Marson"
      }
    end
    let(:common_properties) do
      {
        initiated_by: "user",
        shop_domain: "my-store.myshopify.com",
        changed_at: timestamp
      }
    end
    let(:base_event_data) do
      {
        app_name: "Lexware Office",
        customer_myshopify_domain: "my-store.myshopify.com",
        customer_info: common_customer_info,
        timestamp: timestamp,
        event_type: "test_type", # Required by log_event, will appear in properties
        payload: common_properties
      }
    end

    it "verifies Install event payload" do
      event_data = base_event_data.merge(event_name: "Install")

      expect(client).to receive(:create_event) do |body|
        attributes = body[:data][:attributes]

        # Verify Profile
        profile_attrs = attributes[:profile][:data][:attributes]
        expect(profile_attrs).to include(
          email: "sarah.mason@test.com",
          first_name: "Sarah",
          last_name: "Marson"
        )

        # Verify Metric
        metric_attrs = attributes[:metric][:data][:attributes]
        expect(metric_attrs[:name]).to eq("Install")

        # Verify Properties
        props = attributes[:properties]
        expect(props).to include(
          app_name: "Lexware Office",
          changed_at: timestamp,
          initiated_by: "user",
          shop_domain: "my-store.myshopify.com"
        )
      end

      adapter.capture_event(event_data)
    end

    it "verifies Activation event payload" do
      event_data = base_event_data.merge(
        event_name: "Activated",
        payload: common_properties.merge(
          app_plan: "Premium",
          plan_value: 49.0
        )
      )

      expect(client).to receive(:create_event) do |body|
        attributes = body[:data][:attributes]
        expect(attributes[:metric][:data][:attributes][:name]).to eq("Activated")

        props = attributes[:properties]
        expect(props).to include(
          app_name: "Lexware Office",
          app_plan: "Premium",
          plan_value: 49.0,
          changed_at: timestamp,
          initiated_by: "user",
          shop_domain: "my-store.myshopify.com"
        )
      end

      adapter.capture_event(event_data)
    end

    it "verifies Uninstall event payload" do
      event_data = base_event_data.merge(
        event_name: "Uninstall",
        payload: common_properties.merge(
          app_plan: "Premium",
          plan_value: 49.0
        )
      )

      expect(client).to receive(:create_event) do |body|
        attributes = body[:data][:attributes]
        expect(attributes[:metric][:data][:attributes][:name]).to eq("Uninstall")

        props = attributes[:properties]
        expect(props).to include(
          app_name: "Lexware Office",
          app_plan: "Premium",
          plan_value: 49.0,
          changed_at: timestamp,
          initiated_by: "user",
          shop_domain: "my-store.myshopify.com"
        )
      end

      adapter.capture_event(event_data)
    end

    it "verifies Connection Loss event payload" do
      event_data = base_event_data.merge(
        event_name: "Verbindung getrennt",
        payload: common_properties.merge(
          app_plan: "Premium",
          plan_value: 49.0
        )
      )

      expect(client).to receive(:create_event) do |body|
        attributes = body[:data][:attributes]
        expect(attributes[:metric][:data][:attributes][:name]).to eq("Verbindung getrennt")

        props = attributes[:properties]
        expect(props).to include(
          app_name: "Lexware Office",
          app_plan: "Premium",
          plan_value: 49.0,
          changed_at: timestamp,
          initiated_by: "user",
          shop_domain: "my-store.myshopify.com"
        )
      end

      adapter.capture_event(event_data)
    end
  end
end
