require "rails_helper"

RSpec.describe Entry, type: :model do
  def row(rank:, title: "Story #{rank}")
    { rank: rank, title: title, word_count: 2, points_count: 10, comments_count: 3 }
  end

  describe ".replace_all!" do
    it "stores the given rows" do
      described_class.replace_all!([ row(rank: 1, title: "NP_R ≠ PAR_R"), row(rank: 2) ])

      expect(described_class.order(:rank).pluck(:rank, :title)).to eq([ [ 1, "NP_R ≠ PAR_R" ], [ 2, "Story 2" ] ])
    end

    it "replaces the previous snapshot instead of adding to it" do
      create(:entry, rank: 31, title: "Yesterday's story", word_count: 2, points_count: 1, comments_count: 0)

      described_class.replace_all!([ row(rank: 1) ])

      expect(described_class.pluck(:title)).to eq([ "Story 1" ])
    end

    it "keeps the previous snapshot when the new one fails to save" do
      kept = create(:entry, rank: 1, title: "Still here", word_count: 2, points_count: 5, comments_count: 1)

      expect { described_class.replace_all!([ row(rank: 1), row(rank: 1) ]) }
        .to raise_error(ActiveRecord::RecordNotUnique)
      expect(described_class.all).to contain_exactly(kept)
    end
  end

  describe ".scraped_at" do
    it "is when the stored snapshot was saved" do
      freeze_time
      described_class.replace_all!([ row(rank: 1) ])

      expect(described_class.scraped_at).to eq(Time.current)
    end

    it "is nil when nothing has been scraped yet" do
      expect(described_class.scraped_at).to be_nil
    end
  end
end
