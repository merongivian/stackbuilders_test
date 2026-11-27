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

  def entry(rank:, words:, comments: 0, points: 0)
    create(:entry, rank: rank, title: "Story #{rank}", word_count: words,
                   comments_count: comments, points_count: points)
  end

  describe ".long_titles" do
    it "keeps only titles with more than five words" do
      six = entry(rank: 1, words: 6)
      entry(rank: 2, words: 5)

      expect(described_class.long_titles).to contain_exactly(six)
    end

    it "orders by number of comments, most first" do
      few = entry(rank: 1, words: 7, comments: 3)
      many = entry(rank: 2, words: 8, comments: 90)

      expect(described_class.long_titles).to eq([ many, few ])
    end

    it "breaks ties by front-page rank" do
      second = entry(rank: 2, words: 6, comments: 10)
      first = entry(rank: 1, words: 6, comments: 10)

      expect(described_class.long_titles).to eq([ first, second ])
    end
  end

  describe ".short_titles" do
    it "keeps only titles with five words or fewer" do
      five = entry(rank: 1, words: 5)
      entry(rank: 2, words: 6)

      expect(described_class.short_titles).to contain_exactly(five)
    end

    it "orders by points, most first" do
      few = entry(rank: 1, words: 2, points: 4)
      many = entry(rank: 2, words: 3, points: 400)

      expect(described_class.short_titles).to eq([ many, few ])
    end

    it "breaks ties by front-page rank" do
      second = entry(rank: 2, words: 4, points: 10)
      first = entry(rank: 1, words: 4, points: 10)

      expect(described_class.short_titles).to eq([ first, second ])
    end
  end

  describe ".filtered_by" do
    let!(:long) { entry(rank: 2, words: 6, comments: 1) }
    let!(:short) { entry(rank: 1, words: 2, points: 1) }

    it "returns every entry in rank order without a filter" do
      expect(described_class.filtered_by(nil)).to eq([ short, long ])
    end

    it "applies a known filter" do
      expect(described_class.filtered_by("long_titles")).to eq([ long ])
      expect(described_class.filtered_by("short_titles")).to eq([ short ])
    end

    it "is nil for an unknown filter" do
      expect(described_class.filtered_by("destroy_all")).to be_nil
      expect(described_class.count).to eq(2)
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
