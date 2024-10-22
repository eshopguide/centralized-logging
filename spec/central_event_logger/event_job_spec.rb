# frozen_string_literal: true

require "rails_helper"
require "central_event_logger/event_job"
require "central_event_logger/api_client"

RSpec.describe CentralEventLogger::EventJob, type: :job do
  let(:event_data) do
    {
      app_name: "Test App",
      customer_myshopify_domain: "test-shop.myshopify.com",
      event_name: "test_event",
      event_type: "test_type",
      event_value: "test_value",
      payload: { key: "value" },
      timestamp: Time.now.iso8601
    }
  end

  let(:configuration) { instance_double(CentralEventLogger::Configuration, job_queue_name: "test_queue") }
  let(:api_client) { instance_double(CentralEventLogger::ApiClient) }
  let(:logger) { instance_double("Logger", error: nil) }

  before do
    allow(CentralEventLogger).to receive(:configuration).and_return(configuration)
    allow(CentralEventLogger::ApiClient).to receive(:new).and_return(api_client)
    allow(Rails).to receive(:logger).and_return(logger)

    allow(configuration).to receive(:api_base_url).and_return("https://api.example.com")
    allow(configuration).to receive(:api_key).and_return("test_api_key")
    allow(configuration).to receive(:api_secret).and_return("test_api_secret")
  end

  it "sends event data to the API" do
    expect(CentralEventLogger::ApiClient).to receive(:new).with(
      "https://api.example.com",
      "test_api_key",
      "test_api_secret"
    ).and_return(api_client)
    expect(api_client).to receive(:create_event).with(event_data).and_return({ "status" => "success" })

    perform_enqueued_jobs { CentralEventLogger::EventJob.perform_later(event_data) }
  end

  context "when API request fails" do
    before do
      allow(api_client).to receive(:create_event).and_raise(RuntimeError, "API request failed")
    end

    it "logs the error and re-raises the exception" do
      expect(logger).to receive(:error).with("EventJob failed: API request failed")

      expect do
        CentralEventLogger::EventJob.perform_now(event_data)
      end.to raise_error(RuntimeError, "API request failed")
    end
  end
end
