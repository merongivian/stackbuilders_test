class EntriesController < ActionController::API
  before_action :require_user

  def index
    @filter = params[:filter].presence
    return render_unknown_filter if @filter && Entry::FILTERS.exclude?(@filter)

    @cache_hit = !HackerNews::Snapshot.new.refresh_if_stale!
    @entries = Entry.filtered_by(@filter)
    @fetched_at = Entry.scraped_at
    # Rendered here, not implicitly after the action, so it happens before the
    # log is written in `ensure`.
    render :index
  rescue HackerNews::Error
    # The snapshot falls back to stale entries, so this only happens when
    # nothing has been stored yet.
    render json: { error: "Hacker News is unavailable, try again later" }, status: :service_unavailable
  ensure
    # Also runs on unexpected errors, which are logged as 200: Rails turns them
    # into a 500 only after the action.
    log_request
  end

  private

  def require_user
    return if params[:user].present?

    render json: { error: "Missing user. Pass your name as ?user=<name>" }, status: :bad_request
  end

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
