require "rails_helper"

# Builds every factory and fails if any of them produces an invalid record,
# so a broken factory is caught here instead of in an unrelated spec.
RSpec.describe "Factories" do
  it "are all valid" do
    expect { FactoryBot.lint(traits: true) }.not_to raise_error
  end

  it "short syntax (build/create) is available in specs" do
    expect(self).to respond_to(:build, :create)
  end
end
