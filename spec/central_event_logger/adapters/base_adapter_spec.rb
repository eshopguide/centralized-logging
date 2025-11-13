# frozen_string_literal: true

require "rails_helper"
require "central_event_logger/adapters/base_adapter"

RSpec.describe CentralEventLogger::Adapters::BaseAdapter do
  describe ".available?" do
    it "raises NotImplementedError" do
      config = double("config")
      expect { described_class.available?(config) }.to raise_error(NotImplementedError, /must implement .available?/)
    end
  end

  describe "#capture_event" do
    it "raises NotImplementedError" do
      adapter = described_class.new
      event_data = {}
      expect { adapter.capture_event(event_data) }.to raise_error(NotImplementedError, /must implement #capture_event/)
    end
  end
end
