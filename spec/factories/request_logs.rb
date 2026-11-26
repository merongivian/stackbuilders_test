FactoryBot.define do
  factory :request_log do
    filter_type { "long_titles" }
    user { nil }

    trait :with_user do
      user
    end
  end
end
