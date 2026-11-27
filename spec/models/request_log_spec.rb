require "rails_helper"

RSpec.describe RequestLog, type: :model do
  it "requires the applied filter" do
    log = build(:request_log, filter_type: "", user_name: "jose")

    expect(log).not_to be_valid
    expect(log.errors[:filter_type]).to include("can't be blank")
  end

  it "requires the name of the user who made the request" do
    log = build(:request_log, filter_type: "long_titles", user_name: "")

    expect(log).not_to be_valid
    expect(log.errors[:user_name]).to include("can't be blank")
  end
end
