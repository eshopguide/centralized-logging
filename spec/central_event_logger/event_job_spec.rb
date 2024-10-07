# frozen_string_literal: true

require "rails_helper"
require "central_event_logger/event_job"

RSpec.describe CentralEventLogger::EventJob, type: :job do
  let(:event_data) do
    {
      app_id: "test_app_id",
      event_name: "test_event",
      event_type: "test_type",
      event_value: "test_value",
      customer_id: 1,
      payload: {},
      timestamp: Time.now
    }
  end

  it "creates an event record in the database" do
    allow(ActiveRecord::Base).to receive(:establish_connection)
    expect(CentralEventLogger::Models::Event).to receive(:create!).with(hash_including(event_data))

    perform_enqueued_jobs { CentralEventLogger::EventJob.perform_later(event_data) }
  end
end
