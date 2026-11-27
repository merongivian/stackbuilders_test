require "rails_helper"

RSpec.describe HackerNews::Snapshot do
  # Real fetcher, client and parser; only the HTTP response is faked.
  def fetcher(body: nil, error: nil)
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/") { error ? raise(error) : [ 200, {}, body ] }
    end
    connection = Faraday.new(url: HackerNews::Client::URL) { |f| f.adapter :test, stubs }

    HackerNews::Fetcher.new(client: HackerNews::Client.new(connection: connection))
  end

  def snapshot(fetcher)
    described_class.new(fetcher: fetcher)
  end

  let(:front_page) { fetcher(body: File.read(Rails.root.join("spec/fixtures/files/hacker_news/front_page.html"))) }
  let(:empty_page) { fetcher(body: "<html><body><table></table></body></html>") }
  let(:down) { fetcher(error: Faraday::ConnectionFailed.new("connection refused")) }

  describe "#refresh!" do
    it "stores every scraped entry with its word count" do
      snapshot(front_page).refresh!

      expect(Entry.count).to eq(30)
      expect(Entry.find_by!(rank: 1)).to have_attributes(
        title: "NP_R ≠ PAR_R", word_count: 2, points_count: 38, comments_count: 14
      )
    end

    it "keeps the stored entries when Hacker News is unreachable" do
      kept = create(:entry, rank: 1, title: "Still here", word_count: 2, points_count: 5, comments_count: 1)

      expect { snapshot(down).refresh! }.to raise_error(HackerNews::Error)
      expect(Entry.all).to contain_exactly(kept)
    end

    it "keeps the stored entries when the page has no entries" do
      kept = create(:entry, rank: 1, title: "Still here", word_count: 2, points_count: 5, comments_count: 1)

      expect { snapshot(empty_page).refresh! }.to raise_error(HackerNews::Error)
      expect(Entry.all).to contain_exactly(kept)
    end
  end

  describe "#refresh_if_stale!" do
    # `travel` drops microseconds, so start from a whole second to keep the
    # TTL boundary exact.
    before { freeze_time }

    it "scrapes when nothing has been stored yet" do
      expect(snapshot(front_page).refresh_if_stale!).to be(true)
      expect(Entry.count).to eq(30)
    end

    it "reuses entries younger than the TTL without scraping" do
      snapshot(front_page).refresh!
      travel(described_class::TTL - 1.second)

      expect(snapshot(down).refresh_if_stale!).to be(false)
      expect(Entry.count).to eq(30)
    end

    it "keeps serving stale entries when Hacker News is down" do
      kept = create(:entry, rank: 1, title: "Old story", word_count: 2, points_count: 5, comments_count: 1)
      travel(described_class::TTL)

      scraped = nil
      errors = reported_errors { scraped = snapshot(down).refresh_if_stale! }

      expect(scraped).to be(false)
      expect(errors).to contain_exactly(an_instance_of(HackerNews::Client::Error))
      expect(Entry.all).to contain_exactly(kept)
    end

    it "raises when Hacker News is down and nothing is stored" do
      expect { snapshot(down).refresh_if_stale! }.to raise_error(HackerNews::Error)
    end

    it "scrapes again once the entries reach the TTL" do
      create(:entry, rank: 1, title: "Old story", word_count: 2, points_count: 5, comments_count: 1)
      travel(described_class::TTL)

      expect(snapshot(front_page).refresh_if_stale!).to be(true)
      expect(Entry.where(title: "Old story")).to be_empty
    end
  end
end
