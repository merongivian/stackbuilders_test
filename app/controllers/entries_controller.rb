# JSON API over the stored Hacker News front page.
#
#   GET /entries                      every entry, by rank
#   GET /entries?filter=long_titles   more than five words, most comments first
#   GET /entries?filter=short_titles  five words or fewer, most points first
class EntriesController < ActionController::API
  # Only reached when Hacker News fails and nothing is stored to fall back on.
  rescue_from HackerNews::Error do
    render json: { error: "Hacker News is unavailable, try again later" }, status: :service_unavailable
  end

  def index
    @filter = params[:filter].presence
    # Checked before refreshing so a bad request never triggers a scrape. The
    # relation is lazy, so it is loaded after the refresh below.
    @entries = Entry.filtered_by(@filter) or return render_unknown_filter

    HackerNews::Snapshot.new.refresh_if_stale!
    @fetched_at = Entry.scraped_at
  end

  private

  def render_unknown_filter
    render json: { error: "Unknown filter '#{@filter}'. Valid filters: #{Entry::FILTERS.join(", ")}" },
           status: :bad_request
  end
end
