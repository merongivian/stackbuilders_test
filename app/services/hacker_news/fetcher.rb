module HackerNews
  # Crawls the front page and returns its entries in page order. The front page
  # always lists 30 entries, so there is nothing to cap.
  #
  #   HackerNews::Fetcher.new.call # => [#<HackerNews::Entry rank=1 ...>, ...]
  class Fetcher
    def initialize(client: Client.new)
      @client = client
    end

    # Raises HackerNews::Error when the page lists no entries: the front page
    # always has stories, so an empty result means the markup changed or the
    # page is broken, and returning [] would hide that.
    def call
      rows = Nokogiri::HTML5(@client.get).css("tr.athing")
      raise Error, "Hacker News page has no entries" if rows.empty?

      rows.map { |row| Entry.new(row) }
    end
  end
end
