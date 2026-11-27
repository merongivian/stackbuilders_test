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
      rank: 2, title: "AMD Specific Patches for Llama.cpp", points_count: 19, comments_count: 4
    )
  end
end
