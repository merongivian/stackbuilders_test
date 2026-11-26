class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      # Position on the front page (1-30). It identifies the slot, not the
      # story: the same story moves between ranks over time.
      t.bigint :rank, null: false
      t.string :title, null: false
      # Words in the title, computed when the entry is scraped (symbols on
      # their own don't count). Stored so the title filters run in SQL.
      t.integer :word_count, null: false
      # Job posts on HN have no points or comments, so both default to 0.
      t.integer :comments_count, null: false, default: 0
      t.integer :points_count, null: false, default: 0

      t.timestamps
    end
    add_index :entries, :rank, unique: true
  end
end
