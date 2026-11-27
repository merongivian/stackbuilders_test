# One story on the Hacker News front page. The table holds a single snapshot of
# the page, replaced as a whole on every refresh, so `rank` is the story's
# position in that snapshot rather than a stable identity.
class Entry < ApplicationRecord
  # Titles with more words than this are long; the rest are short.
  TITLE_WORD_LIMIT = 5

  # The filters a client may ask for, each named after its scope below.
  FILTERS = %w[long_titles short_titles].freeze

  scope :ranked, -> { order(:rank) }
  # Ties are broken by front-page rank so the order is always the same.
  scope :long_titles, -> { where(word_count: (TITLE_WORD_LIMIT + 1)..).order(comments_count: :desc, rank: :asc) }
  scope :short_titles, -> { where(word_count: ..TITLE_WORD_LIMIT).order(points_count: :desc, rank: :asc) }

  # Entries for the named filter, every entry by rank when no filter is given,
  # or nil for an unknown filter. Only names in FILTERS reach public_send.
  def self.filtered_by(name)
    return ranked if name.blank?

    public_send(name) if FILTERS.include?(name)
  end

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
