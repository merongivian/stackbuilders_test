FactoryBot.define do
  factory :user do
    name { "Ada Lovelace" }
    sequence(:email) { |n| "user#{n}@example.com" }
  end
end
