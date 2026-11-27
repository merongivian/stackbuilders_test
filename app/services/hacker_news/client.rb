module HackerNews
  class Client
    class Error < HackerNews::Error; end

    URL = "https://news.ycombinator.com/".freeze
    USER_AGENT = "hackernews-crawler/1.0".freeze
    TIMEOUT = 5 # seconds, for both connecting and reading

    def initialize(connection: nil)
      @connection = connection || build_connection
    end

    def get
      response = @connection.get

      raise Error, "Hacker News responded with #{response.status}" unless response.success?

      response.body
    rescue Faraday::Error => error
      raise Error, "Hacker News request failed: #{error.message}"
    end

    private

    def build_connection
      Faraday.new(url: URL, headers: { "User-Agent" => USER_AGENT }) do |connection|
        connection.options.timeout = TIMEOUT
        connection.options.open_timeout = TIMEOUT
      end
    end
  end
end
