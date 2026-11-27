# The table holds one snapshot of the front page, replaced as a whole on every
# refresh, so `rank` is a position in that snapshot, not a story's identity.
class Entry < ApplicationRecord
  SHORT_TITLE_MAX_WORDS = 5
  FILTERS = %w[long_titles short_titles].freeze

  scope :ranked, -> { order(:rank) }
  scope :long_titles, -> { where(word_count: (SHORT_TITLE_MAX_WORDS + 1)..).order(comments_count: :desc, rank: :asc) }
  scope :short_titles, -> { where(word_count: ..SHORT_TITLE_MAX_WORDS).order(points_count: :desc, rank: :asc) }

  def self.filtered_by(name)
    return ranked if name.blank?

    public_send(name) if FILTERS.include?(name)
  end

  def self.replace_all!(rows)
    now = Time.current

    transaction do
      delete_all
      insert_all!(rows.map { |row| row.merge(created_at: now, updated_at: now) })
    end
  end

  def self.scraped_at
    maximum(:created_at)
  end
end
