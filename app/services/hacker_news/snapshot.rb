module HackerNews
  # `::Entry` is the model; a bare `Entry` here would be HackerNews::Entry.
  class Snapshot
    MAX_AGE = 5.minutes

    def initialize(fetcher: Fetcher.new)
      @fetcher = fetcher
    end

    def refresh!
      ::Entry.replace_all!(@fetcher.call.map(&:to_h))
    end

    # Returns true when it scraped Hacker News, false when the stored entries
    # were reused, including stale ones kept because Hacker News failed.
    def refresh_if_stale!
      return false if fresh?

      refresh!
      true
    rescue HackerNews::Error => error
      raise unless ::Entry.exists?

      Rails.error.report(error, handled: true)
      false
    end

    def fresh?
      scraped_at = ::Entry.scraped_at
      scraped_at.present? && scraped_at > MAX_AGE.ago
    end
  end
end
