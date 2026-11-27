module HackerNews
  class Entry
    LETTER_OR_DIGIT = /[\p{L}\p{N}]/

    def initialize(row)
      @row = row
    end

    def rank
      number(@row.at_css("span.rank")&.text)
    end

    def title
      @row.at_css("span.titleline > a")&.text&.strip
    end

    def word_count
      title.to_s.split.count { |token| token.match?(LETTER_OR_DIGIT) }
    end

    def points_count
      number(subtext&.at_css("span.score")&.text)
    end

    # The last link reads "N comments", or "discuss" when there are none.
    def comments_count
      link = subtext&.css("a")&.reverse&.find { |a| a.text.match?(/\bcomments?\b|discuss/i) }

      number(link&.text)
    end

    def to_h
      { rank: rank, title: title, word_count: word_count, points_count: points_count, comments_count: comments_count }
    end

    private

    # Hacker News puts points and comments in the row after the title row.
    def subtext
      @row.xpath("following-sibling::tr[1]").first&.at_css("td.subtext")
    end

    def number(text)
      text.to_s.delete(",")[/\d+/].to_i
    end
  end
end
