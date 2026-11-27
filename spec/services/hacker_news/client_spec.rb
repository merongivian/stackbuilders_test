require "rails_helper"

RSpec.describe HackerNews::Client do
  def client(stubs)
    connection = Faraday.new(url: described_class::URL) { |f| f.adapter :test, stubs }
    described_class.new(connection: connection)
  end

  def respond(status: 200, body: "")
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/") { [ status, {}, body ] }
    end
  end

  it "returns the response body" do
    body = "<html><body>Hacker News</body></html>"

    expect(client(respond(body: body)).get).to eq(body)
  end

  it "raises errors callers can rescue as HackerNews::Error" do
    expect { client(respond(status: 503)).get }.to raise_error(HackerNews::Error)
  end

  it "raises its own error for a non-success response" do
    expect { client(respond(status: 503)).get }
      .to raise_error(described_class::Error, /503/)
  end

  it "raises its own error when the request itself fails" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/") { raise Faraday::TimeoutError, "timed out" }
    end

    expect { client(stubs).get }
      .to raise_error(described_class::Error, /timed out/)
  end
end
