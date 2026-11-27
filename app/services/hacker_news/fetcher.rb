module HackerNews
  # Crawls the front page and returns its entries in page order. The front page
  # always lists 30 entries, so there is nothing to cap.
  #
  #   HackerNews::Fetcher.new.call # => [#<HackerNews::Entry rank=1 ...>, ...]
  class Fetcher
    def initialize(client: Client.new)
      @client = client
    end

    def call
      Nokogiri::HTML5(@client.get).css("tr.athing").map { |row| Entry.new(row) }
    end
  end
end
