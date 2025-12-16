# frozen_string_literal: true

require "rails_helper"
require "central_event_logger/adapters/central_api_adapter"

RSpec.describe CentralEventLogger::Adapters::CentralApiAdapter do
  let(:base_url) { "https://api.example.com" }
  let(:api_key) { "test_api_key" }
  let(:api_secret) { "test_api_secret" }
  
  subject(:adapter) { described_class.new(base_url, api_key, api_secret) }

  describe ".available?" do
    let(:config) { double("config") }

    it "returns true when api_base_url is configured" do
      allow(config).to receive(:api_base_url).and_return("https://api.example.com")
      expect(described_class.available?(config)).to be true
    end

    it "returns false when api_base_url is nil" do
      allow(config).to receive(:api_base_url).and_return(nil)
      expect(described_class.available?(config)).to be false
    end
  end

  describe ".from_config" do
    let(:config) { double("config", api_base_url: base_url, api_key: api_key, api_secret: api_secret) }

    it "creates a new instance with config values" do
      instance = described_class.from_config(config)
      expect(instance).to be_a(described_class)
      expect(instance.instance_variable_get(:@base_url)).to eq(base_url)
      expect(instance.instance_variable_get(:@api_key)).to eq(api_key)
      expect(instance.instance_variable_get(:@api_secret)).to eq(api_secret)
    end
  end

  describe "#capture_event" do
    let(:event_data) do
      {
        event_name: "test_event",
        payload: { key: "value" }
      }
    end

    let(:uri) { URI("#{base_url}/api/v1/events") }
    let(:http) { instance_double(Net::HTTP) }
    let(:request) { instance_double(Net::HTTP::Post) }
    let(:response) { instance_double(Net::HTTPSuccess, is_a?: true, body: '{"success": true}') }

    before do
      allow(Net::HTTP).to receive(:new).with(uri.host, uri.port).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(Net::HTTP::Post).to receive(:new).with(uri.path).and_return(request)
      allow(request).to receive(:[]=)
      allow(request).to receive(:body=)
      allow(http).to receive(:request).with(request).and_return(response)
    end

    it "sends a POST request to the API" do
      expect(http).to receive(:use_ssl=).with(true)
      expect(request).to receive(:[]=).with("Content-Type", "application/json")
      expect(request).to receive(:[]=).with("X-API-Key", api_key)
      expect(request).to receive(:[]=).with("X-API-Secret", api_secret)
      expect(request).to receive(:body=).with({ event: event_data }.to_json)
      expect(http).to receive(:request).with(request)

      result = adapter.capture_event(event_data)
      expect(result).to eq({ "success" => true })
    end

    context "when API request fails" do
      let(:response) { instance_double(Net::HTTPNotFound, is_a?: false, code: "404", message: "Not Found") }

      it "raises an error" do
        expect { adapter.capture_event(event_data) }.to raise_error(RuntimeError, "API request failed: 404 - Not Found")
      end
    end
  end
end

