module HackerNews
  # Keeps the stored front page (the entries table) fresh. A scrape is reused
  # for TTL before Hacker News is hit again, so most requests are a database
  # read.
  #
  #   HackerNews::Snapshot.new.refresh_if_stale! # => true when it scraped
  class Snapshot
    # How long a scraped front page is reused before scraping again.
    TTL = 5.minutes

    def initialize(fetcher: Fetcher.new)
      @fetcher = fetcher
    end

    # Scrapes and replaces the stored entries. Scraping fails with
    # HackerNews::Error before anything is stored, so the old entries stay.
    def refresh!
      ::Entry.replace_all!(@fetcher.call.map(&:to_h))
    end

    # Refreshes only when nothing is stored or the entries reached the TTL.
    # Returns true when it scraped, false when the stored entries were reused.
    def refresh_if_stale!
      return false if fresh?

      refresh!
      true
    end

    def fresh?
      scraped_at = ::Entry.scraped_at
      scraped_at.present? && scraped_at > TTL.ago
    end
  end
end
