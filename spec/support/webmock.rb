require "webmock/rspec"

# Specs never reach the real Hacker News; requests to it must be stubbed.
WebMock.disable_net_connect!
