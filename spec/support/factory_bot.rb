# Lets specs call `create(:entry)` / `build(:entry)` instead of
# `FactoryBot.create(:entry)`.
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
