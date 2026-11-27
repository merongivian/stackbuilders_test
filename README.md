# Hacker News crawler

A Rails JSON API that scrapes the first 30 entries of
[Hacker News](https://news.ycombinator.com/) (rank, title, points and number of
comments), filters them by title length, and logs every request.

```bash
curl 'localhost:3000/entries?user=jose&filter=long_titles'
```

## Getting started

Requirements: Ruby 4.0.10 (see `.ruby-version`) and PostgreSQL.

```bash
bin/setup --skip-server   # install gems and prepare the database
bin/rails server          # http://localhost:3000
bundle exec rspec         # run the tests; Hacker News is stubbed, no network needed
```

## API

`GET /entries` takes two query parameters:

| Parameter | Required | Values |
|---|---|---|
| `user` | yes | any name identifying the caller, e.g. `jose` |
| `filter` | no | `long_titles` or `short_titles`; omit for every entry |

| Filter | Entries | Order |
|---|---|---|
| _(none)_ | all 30 | rank on the front page |
| `long_titles` | titles with **more than five** words | most comments first |
| `short_titles` | titles with **five or fewer** words | most points first |

Ties are broken by rank, so the order is always the same.

```bash
curl 'localhost:3000/entries?user=jose&filter=short_titles'
```

```json
{
  "filter": "short_titles",
  "fetched_at": "2026-11-27T22:45:37.890Z",
  "entries": [
    { "rank": 18, "title": "AI made self-hosting fun again", "points": 1074, "comments": 500, "word_count": 5 }
  ]
}
```

`fetched_at` is when the entries were scraped. Errors are JSON too:

| Status | When |
|---|---|
| `400` | `user` is missing, or `filter` is not one of the values above (names are case-sensitive) |
| `503` | Hacker News can't be reached and nothing has been scraped yet |

## Counting words

A title is split on whitespace, and a token counts as a word when it has at
least one letter or digit. In "This is - a self-explained example" the lone `-`
is not a word, while `self-explained` stays one word, giving 5 (splitting on the
hyphen would give 6). Punctuation attached to a
word stays with it (`HN:`, `C++`, `1.80`), and letters in any script count.

## Usage log

Every request with a `user` is stored in `request_logs`:

| Column | Meaning |
|---|---|
| `created_at` | when the request was made |
| `filter_type` | the filter asked for: `long_titles`, `short_titles`, `none`, or the rejected value |
| `user_name` | who made the request |
| `status` | HTTP status of the response |
| `cache_hit` | `true` when served from the stored entries, `false` when Hacker News was scraped |
| `entries_returned` | how many entries were returned |

`user_name` and `status` track user interaction; `cache_hit` and
`entries_returned` track crawler behaviour.

## Design decisions

**Scrape at most every five minutes.** Requests are answered from the `entries`
table, which holds one snapshot of the front page. When that snapshot is older
than five minutes, the next request scrapes Hacker News again before answering.
Most requests are a single database query (about 10 ms instead of about 500 ms
for a scrape), and Hacker News isn't hit on every request. The cost is that
results can be up to five minutes behind the live page.

**Replace the whole snapshot at once.** A refresh deletes the old rows and
inserts the new ones in one transaction, so a reader never sees a half-written
or empty table, and a failed save keeps the old rows.

**Rank is a position, not an identity.** A story moves between ranks, and rank
3 is a different story an hour later. Since the snapshot is replaced as a
whole, nothing needs to follow a story across scrapes, so Hacker News' item id
isn't stored.

**Count words once, filter in SQL.** The word count is computed when an entry is
scraped and stored in `word_count`, so each filter is a plain database query.

**Keep serving when Hacker News is down.** If a refresh fails while entries are
stored, the stale entries are served and the error is reported. The API only
returns `503` when there is nothing to fall back on. A page with no entries
counts as a failure too: it means the markup changed, and storing nothing would
hide that.

**A name instead of accounts.** Callers identify themselves with `?user=<name>`.
There is no authentication: the name is for tracking usage, not access control.

### Code layout

| Piece | Responsibility |
|---|---|
| `HackerNews::Client` | fetches the page (Faraday, 5 s timeouts) |
| `HackerNews::Fetcher` | parses it with Nokogiri into entries |
| `HackerNews::Entry` | reads rank, title, points, comments and word count from one row |
| `HackerNews::Snapshot` | decides when to scrape and stores the result |
| `Entry` model | the stored entries, the filters, the atomic replace |
| `EntriesController` | parameters, the JSON response, the usage log |

Every scraping failure is a `HackerNews::Error`, so callers rescue one class.

### Left out on purpose

- **History of past scrapes.** Only the current front page is kept.
- **A lock around refreshes.** Two requests arriving at the same moment on a
  stale snapshot may both scrape. The transaction keeps the data correct, so a
  lock wasn't worth it at this scale.
- **Request duration.** Response time isn't logged; `cache_hit` shows whether
  Hacker News was scraped.

## Testing

RSpec covers each layer: the parser against saved copies of the real front
page, the word count against the example above and edge cases, the refresh and
five-minute rules with a frozen clock, and the API end to end with Hacker News
stubbed by WebMock (which also blocks any real HTTP in the suite).
