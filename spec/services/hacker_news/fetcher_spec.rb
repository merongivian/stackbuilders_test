require "rails_helper"

RSpec.describe HackerNews::Fetcher do
  let(:front_page) do
    File.read(Rails.root.join("spec/fixtures/files/hacker_news/front_page.html"))
  end
  let(:client) { instance_double(HackerNews::Client, get: front_page) }

  def fetcher
    described_class.new(client: client)
  end

  it "returns the entries as HackerNews::Entry objects" do
    entries = fetcher.call

    expect(entries).to all(be_a(HackerNews::Entry))
    expect(entries.size).to eq(30)
  end

  it "keeps the page order, starting at rank 1" do
    expect(fetcher.call.map(&:rank)).to eq((1..30).to_a)
  end

  it "reads real values off the page" do
    first = fetcher.call.first

    expect(first.title).to eq("NP_R ≠ PAR_R")
    expect(first.points_count).to eq(38)
    expect(first.comments_count).to eq(14)
  end

  it "returns every entry the page lists" do
    subset = File.read(Rails.root.join("spec/fixtures/files/hacker_news/front_page_subset.html"))
    allow(client).to receive(:get).and_return(subset)

    expect(fetcher.call.size).to eq(4)
  end

  # The front page always lists stories, so finding none means the markup
  # changed or the page is broken; storing nothing would hide that.
  it "raises for a page with no entries" do
    allow(client).to receive(:get).and_return("<html><body><table></table></body></html>")

    expect { fetcher.call }.to raise_error(HackerNews::Error, /no entries/)
  end
end
