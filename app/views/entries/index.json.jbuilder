json.filter @filter
json.fetched_at @fetched_at

json.entries @entries do |entry|
  json.rank entry.rank
  json.title entry.title
  json.points entry.points_count
  json.comments entry.comments_count
  json.word_count entry.word_count
end
