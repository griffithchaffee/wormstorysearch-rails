FactoryBot.define do
  factory(:story) do
    title { FactoryBot.generate(:uniq_s) }
    word_count { rand(0..2_000_000) }
    author { FactoryBot.create(:story_author) }
    story_created_on { FactoryBot.generate(:date_in_past) }
    story_updated_at { FactoryBot.generate(:time_in_past) }
  end
end
