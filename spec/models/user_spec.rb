require "rails_helper"

RSpec.describe User, type: :model do
  it "requires a name" do
    user = build(:user, name: "", email: "ada@example.com")

    expect(user).not_to be_valid
    expect(user.errors[:name]).to include("can't be blank")
  end

  it "requires an email" do
    user = build(:user, name: "Ada Lovelace", email: "")

    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("can't be blank")
  end

  it "stores the email stripped and lowercased" do
    user = create(:user, name: "Ada Lovelace", email: "  Ada@Example.COM ")

    expect(user.reload.email).to eq("ada@example.com")
  end

  it "rejects an email already taken in a different case" do
    create(:user, name: "Ada Lovelace", email: "ada@example.com")
    duplicate = build(:user, name: "Ada Byron", email: "ADA@example.com")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include("has already been taken")
  end

  it "keeps its request logs, unlinked, when deleted" do
    user = create(:user, name: "Ada Lovelace", email: "ada@example.com")
    log = create(:request_log, filter_type: "long_titles", user: user)

    user.destroy!

    expect(log.reload.user).to be_nil
  end
end
