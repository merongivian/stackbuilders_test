require "rails_helper"

RSpec.describe HackerNews::Entry do
  def document(fixture = "front_page_subset")
    path = Rails.root.join("spec/fixtures/files/hacker_news/#{fixture}.html")
    Nokogiri::HTML5(File.read(path))
  end

  def entry_at(rank, fixture = "front_page_subset")
    row = document(fixture).css("tr.athing").find { |tr| tr.at_css("span.rank").text == "#{rank}." }
    described_class.new(row)
  end

  it "reads the rank from the title row" do
    expect(entry_at(1).rank).to eq(1)
  end

  it "reads the title" do
    expect(entry_at(1).title).to eq("NP_R ≠ PAR_R")
  end

  it "reads points and comments from the subtext row" do
    entry = entry_at(1)

    expect(entry.points_count).to eq(38)
    expect(entry.comments_count).to eq(14)
  end

  it "reads four-digit points and comments" do
    entry = entry_at(3)

    expect(entry.points_count).to eq(1864)
    expect(entry.comments_count).to eq(1712)
  end

  it "ignores thousands separators in points" do
    expect(entry_at(1, "edge_cases").points_count).to eq(1234)
  end

  it "treats 'discuss' as zero comments" do
    expect(entry_at(1, "edge_cases").comments_count).to eq(0)
  end

  it "defaults to zero for a job post with no score and no comment link" do
    entry = entry_at(17)

    expect(entry.points_count).to eq(0)
    expect(entry.comments_count).to eq(0)
  end

  it "exposes a hash for persistence" do
    expect(entry_at(2).to_h).to eq(
      rank: 2, title: "AMD Specific Patches for Llama.cpp", word_count: 5,
      points_count: 19, comments_count: 4
    )
  end

  describe "#word_count" do
    def entry_titled(title)
      html = %(<table><tr class="athing"><td><span class="titleline"><a>#{CGI.escapeHTML(title)}</a></span></td></tr></table>)
      described_class.new(Nokogiri::HTML5(html).at_css("tr.athing"))
    end

    def word_count(title)
      entry_titled(title).word_count
    end

    it "counts the example from the brief as five words" do
      expect(word_count("This is - a self-explained example")).to eq(5)
    end

    it "ignores tokens made only of symbols" do
      expect(word_count("NP_R ≠ PAR_R")).to eq(2)
      expect(word_count("Rails | Ruby & — Postgres")).to eq(3)
    end

    it "keeps punctuation attached to a word as one word" do
      expect(word_count("Show HN: Don't use C++")).to eq(5)
    end

    it "counts numbers as words" do
      expect(word_count("Rust 1.80 released")).to eq(3)
    end

    it "counts words in any script" do
      expect(word_count("Café über naïve 東京")).to eq(4)
    end

    it "treats any run of whitespace as a single separator" do
      expect(word_count("  spaced \t out\nwords  ")).to eq(3)
    end

    it "is zero for a row without a title" do
      row = Nokogiri::HTML5(%(<table><tr class="athing"><td></td></tr></table>)).at_css("tr.athing")

      expect(described_class.new(row).word_count).to eq(0)
    end
  end
end
