require "rails_helper"

RSpec.describe "GET /entries", type: :request do
  let(:hacker_news) { HackerNews::Client::URL }
  let(:front_page) { File.read(Rails.root.join("spec/fixtures/files/hacker_news/front_page.html")) }

  def entry(rank:, title:, words:, comments: 0, points: 0)
    create(:entry, rank: rank, title: title, word_count: words, comments_count: comments, points_count: points)
  end

  def json
    response.parsed_body
  end

  context "with a fresh snapshot" do
    before do
      entry(rank: 1, title: "Short and sweet", words: 3, comments: 1, points: 50)
      entry(rank: 2, title: "A title that is clearly quite long", words: 7, comments: 40, points: 5)
      entry(rank: 3, title: "Another long title with many words", words: 6, comments: 90, points: 1)
      entry(rank: 4, title: "Tiny", words: 1, comments: 2, points: 300)
    end

    it "lists every entry in rank order without a filter" do
      get "/entries"

      expect(response).to have_http_status(:ok)
      expect(json["filter"]).to be_nil
      expect(json["entries"].pluck("rank")).to eq([ 1, 2, 3, 4 ])
    end

    it "describes each entry by rank, title, points, comments and word count" do
      get "/entries"

      expect(json["entries"].first).to eq(
        "rank" => 1, "title" => "Short and sweet", "points" => 50, "comments" => 1, "word_count" => 3
      )
    end

    it "lists long titles by comments with filter=long_titles" do
      get "/entries", params: { filter: "long_titles" }

      expect(json["filter"]).to eq("long_titles")
      expect(json["entries"].pluck("title")).to eq(
        [ "Another long title with many words", "A title that is clearly quite long" ]
      )
    end

    it "lists short titles by points with filter=short_titles" do
      get "/entries", params: { filter: "short_titles" }

      expect(json["entries"].pluck("title")).to eq([ "Tiny", "Short and sweet" ])
    end

    it "says when the entries were scraped" do
      get "/entries"

      expect(Time.zone.parse(json["fetched_at"])).to be_within(1.second).of(Entry.scraped_at)
    end

    it "serves the stored entries without contacting Hacker News" do
      get "/entries"

      expect(a_request(:get, hacker_news)).not_to have_been_made
    end

    it "rejects an unknown filter and names the valid ones" do
      get "/entries", params: { filter: "bogus" }

      expect(response).to have_http_status(:bad_request)
      expect(json["error"]).to eq("Unknown filter 'bogus'. Valid filters: long_titles, short_titles")
    end
  end

  context "with a stale snapshot" do
    before do
      travel_to(HackerNews::Snapshot::TTL.ago) { entry(rank: 1, title: "Old story", words: 2) }
    end

    it "scrapes Hacker News again before answering" do
      stub_request(:get, hacker_news).to_return(status: 200, body: front_page)

      get "/entries"

      expect(json["entries"].size).to eq(30)
      expect(json["entries"].first["title"]).to eq("NP_R ≠ PAR_R")
    end

    it "serves the stale entries when Hacker News is down" do
      stub_request(:get, hacker_news).to_return(status: 503)

      get "/entries"

      expect(response).to have_http_status(:ok)
      expect(json["entries"].pluck("title")).to eq([ "Old story" ])
    end
  end

  context "with nothing stored" do
    it "is unavailable while Hacker News is down" do
      stub_request(:get, hacker_news).to_timeout

      get "/entries"

      expect(response).to have_http_status(:service_unavailable)
      expect(json["error"]).to eq("Hacker News is unavailable, try again later")
    end
  end
end
