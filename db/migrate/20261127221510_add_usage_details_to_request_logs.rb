class AddUsageDetailsToRequestLogs < ActiveRecord::Migration[8.1]
  # How each request went, to track user interaction and crawler behaviour.
  # Nullable: older logs predate these fields, and cache_hit/entries_returned
  # don't apply to requests rejected before reaching the entries.
  def change
    change_table :request_logs, bulk: true do |t|
      t.integer :status         # HTTP status of the response
      t.boolean :cache_hit      # true when served from the stored snapshot
      t.integer :entries_returned
    end
  end
end
