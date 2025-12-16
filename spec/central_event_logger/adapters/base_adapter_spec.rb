# frozen_string_literal: true

require "rails_helper"
require "central_event_logger/adapters/base_adapter"

RSpec.describe CentralEventLogger::Adapters::BaseAdapter do
  let(:config) { double("config") }

  # Create a concrete subclass for testing since BaseAdapter is abstract
  let(:adapter_class) do
    Class.new(CentralEventLogger::Adapters::BaseAdapter) do
      def self.available?(config)
        true
      end

      def self.from_config(config)
        new
      end

      def capture_event(event_data)
        true
      end
    end
  end

  subject(:adapter) { adapter_class.new }

  describe "#whitelisted?" do
    context "when whitelist is not configured" do
      it "returns true for any event" do
        expect(adapter.whitelisted?("some_event")).to be true
        expect(adapter.whitelisted?("another_event")).to be true
      end
    end

    context "when whitelist is empty" do
      before { adapter.event_whitelist = [] }

      it "returns true for any event" do
        expect(adapter.whitelisted?("some_event")).to be true
      end
    end

    context "when whitelist is configured" do
      before { adapter.event_whitelist = %w[allowed_event another_allowed] }

      it "returns true for events in the whitelist" do
        expect(adapter.whitelisted?("allowed_event")).to be true
      end

      it "returns false for events not in the whitelist" do
        expect(adapter.whitelisted?("blocked_event")).to be false
      end
    end
  end
end
