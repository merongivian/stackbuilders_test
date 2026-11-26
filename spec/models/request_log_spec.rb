require "rails_helper"

RSpec.describe RequestLog, type: :model do
  it "requires the applied filter" do
    log = build(:request_log, filter_type: "", user: nil)

    expect(log).not_to be_valid
    expect(log.errors[:filter_type]).to include("can't be blank")
  end

  it "logs anonymous requests without a user" do
    log = build(:request_log, filter_type: "short_titles", user: nil)

    expect(log).to be_valid
  end

  it "links a request to the user who made it" do
    user = create(:user, name: "Ada Lovelace", email: "ada@example.com")
    log = create(:request_log, filter_type: "long_titles", user: user)

    expect(user.request_logs).to contain_exactly(log)
  end
end
