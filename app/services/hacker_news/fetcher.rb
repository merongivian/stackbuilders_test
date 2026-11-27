module HackerNews
  class Fetcher
    def initialize(client: Client.new)
      @client = client
    end

    def call
      rows = Nokogiri::HTML5(@client.get).css("tr.athing")
      raise Error, "Hacker News page has no entries, its markup may have changed" if rows.empty?

      rows.map { |row| Entry.new(row) }
    end
  end
end
