module HackerNews
  class Entry
    def initialize(row)
      @row = row
    end

    def rank
      number(@row.at_css("span.rank")&.text)
    end

    def title
      @row.at_css("span.titleline > a")&.text&.strip
    end

    def points_count
      number(subtext&.at_css("span.score")&.text)
    end

    def comments_count
      link = subtext&.css("a")&.reverse&.find { |a| a.text.match?(/\bcomments?\b|discuss/i) }

      number(link&.text)
    end

    def to_h
      { rank: rank, title: title, points_count: points_count, comments_count: comments_count }
    end

    private

    # The points/comments line is the row right after the title row.
    def subtext
      @row.xpath("following-sibling::tr[1]").first&.at_css("td.subtext")
    end

    def number(text)
      text.to_s.delete(",")[/\d+/].to_i
    end
  end
end
