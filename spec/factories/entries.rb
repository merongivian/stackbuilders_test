FactoryBot.define do
  factory :entry do
    sequence(:rank)
    title { "Show HN: A tiny web crawler" }
    word_count { 6 }
    comments_count { 10 }
    points_count { 100 }
  end
end
