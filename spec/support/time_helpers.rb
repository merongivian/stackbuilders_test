# Lets specs move the clock with `travel` / `travel_to`.
RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end
