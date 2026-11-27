# One story on the Hacker News front page. The table holds a single snapshot of
# the page, replaced as a whole on every refresh, so `rank` is the story's
# position in that snapshot rather than a stable identity.
class Entry < ApplicationRecord
  # Swaps the stored snapshot for `rows` in one transaction, so readers see the
  # old snapshot or the new one, never a mix or an empty table. If the new rows
  # fail to save, the old ones stay.
  def self.replace_all!(rows)
    now = Time.current

    transaction do
      delete_all
      insert_all!(rows.map { |row| row.merge(created_at: now, updated_at: now) })
    end
  end

  # When the stored snapshot was saved, or nil if nothing has been stored yet.
  def self.scraped_at
    maximum(:created_at)
  end
end
