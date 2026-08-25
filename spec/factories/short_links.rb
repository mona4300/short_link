FactoryBot.define do
  factory :short_link do
    original_link { "https://example.com/articles/how-to-build-a-short-link-service" }
    code { "abc1234567" }
  end
end
