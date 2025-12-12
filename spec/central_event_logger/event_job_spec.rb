# frozen_string_literal: true

require "rails_helper"
require "central_event_logger/event_job"
require "central_event_logger/adapters/central_api_adapter"
require "central_event_logger/adapters/adapter_factory"

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

  let(:configuration) do
    instance_double(CentralEventLogger::Configuration, job_queue_name: "test_queue", adapters: [:central_api])
  end
  let(:adapter) { instance_double(CentralEventLogger::Adapters::CentralApiAdapter, capture_event: { "status" => "success" }) }
  let(:logger) { instance_double("Logger", error: nil) }
  let(:error_reporter) { instance_double("ActiveSupport::ErrorReporter", report: nil) }

  before do
    allow(CentralEventLogger).to receive(:configuration).and_return(configuration)
    allow(Rails).to receive(:logger).and_return(logger)
    allow(Rails).to receive(:error).and_return(error_reporter)
  end

  describe "#perform" do
    it "uses AdapterFactory to build and execute adapters" do
      expect(CentralEventLogger::Adapters::AdapterFactory).to receive(:build)
        .with(:central_api, configuration)
        .and_return(adapter)
      expect(adapter).to receive(:capture_event).with(event_data)

      CentralEventLogger::EventJob.perform_now(event_data)
    end

    it "handles multiple adapters" do
      allow(configuration).to receive(:adapters).and_return([:central_api, :posthog])
      adapter1 = instance_double(CentralEventLogger::Adapters::CentralApiAdapter, capture_event: true)
      adapter2 = instance_double(CentralEventLogger::Adapters::PostHogAdapter, capture_event: true)

      expect(CentralEventLogger::Adapters::AdapterFactory).to receive(:build)
        .with(:central_api, configuration)
        .and_return(adapter1)
      expect(CentralEventLogger::Adapters::AdapterFactory).to receive(:build)
        .with(:posthog, configuration)
        .and_return(adapter2)

      expect(adapter1).to receive(:capture_event).with(event_data)
      expect(adapter2).to receive(:capture_event).with(event_data)

      CentralEventLogger::EventJob.perform_now(event_data)
    end

    it "skips adapters that return nil from factory" do
      allow(configuration).to receive(:adapters).and_return([:central_api, :unknown])

      expect(CentralEventLogger::Adapters::AdapterFactory).to receive(:build)
        .with(:central_api, configuration)
        .and_return(adapter)
      expect(CentralEventLogger::Adapters::AdapterFactory).to receive(:build)
        .with(:unknown, configuration)
        .and_return(nil)

      expect(adapter).to receive(:capture_event).with(event_data)

      CentralEventLogger::EventJob.perform_now(event_data)
    end

    context "when adapter request fails" do
      before do
        allow(CentralEventLogger::Adapters::AdapterFactory).to receive(:build)
          .with(:central_api, configuration)
          .and_return(adapter)
        allow(adapter).to receive(:capture_event).and_raise(RuntimeError, "API request failed")
      end

      it "does not raise due to internal rescue and reports error" do
        expect(error_reporter).to receive(:report).with(/CentralEventLogger adapter central_api failed:/)
        CentralEventLogger::EventJob.perform_now(event_data)
      end
    end

    context "with explicit adapters in event_data" do
      let(:event_data_with_adapters) do
        event_data.merge(adapters: [:posthog])
      end

      it "uses adapters from event_data instead of configuration" do
        adapter2 = instance_double(CentralEventLogger::Adapters::PostHogAdapter, capture_event: true)

        expect(CentralEventLogger::Adapters::AdapterFactory).to receive(:build)
          .with(:posthog, configuration)
          .and_return(adapter2)
        expect(adapter2).to receive(:capture_event).with(event_data_with_adapters)

        CentralEventLogger::EventJob.perform_now(event_data_with_adapters)
      end
    end
  end
end
