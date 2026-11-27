# Scrapes the Hacker News front page. Every failure, whether the request
# itself or a page that can't be scraped, is raised as a HackerNews::Error so
# callers have a single error to rescue.
module HackerNews
  class Error < StandardError; end
end
