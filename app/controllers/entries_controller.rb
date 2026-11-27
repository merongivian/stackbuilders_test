# JSON API over the stored Hacker News front page. Callers say who they are
# with ?user=<name>, and every request they make is logged.
#
#   GET /entries?user=jose                      every entry, by rank
#   GET /entries?user=jose&filter=long_titles   more than five words, most comments first
#   GET /entries?user=jose&filter=short_titles  five words or fewer, most points first
class EntriesController < ActionController::API
  before_action :require_user

  def index
    @filter = params[:filter].presence
    # Checked before refreshing so a bad request never triggers a scrape. The
    # relation is lazy, so it is loaded after the refresh below.
    @entries = Entry.filtered_by(@filter) or return render_unknown_filter

    @cache_hit = !HackerNews::Snapshot.new.refresh_if_stale!
    @fetched_at = Entry.scraped_at
    # Rendered explicitly so the response is complete before the log is written.
    render :index
  rescue HackerNews::Error
    # Only reached when Hacker News fails and nothing is stored to fall back on.
    render json: { error: "Hacker News is unavailable, try again later" }, status: :service_unavailable
  ensure
    # Every outcome is logged. An unexpected error is still logged, but as 200,
    # since Rails turns it into a 500 only after the action.
    log_request
  end

  private

  def require_user
    return if params[:user].present?

    render json: { error: "Missing user. Pass your name as ?user=<name>" }, status: :bad_request
  end

  # created_at is the request timestamp.
  def log_request
    RequestLog.create!(
      user_name: params[:user],
      filter_type: @filter || "none",
      status: response.status,
      cache_hit: @cache_hit,
      entries_returned: (@entries.size if response.successful?)
    )
  end

  def render_unknown_filter
    render json: { error: "Unknown filter '#{@filter}'. Valid filters: #{Entry::FILTERS.join(", ")}" },
           status: :bad_request
  end
end
