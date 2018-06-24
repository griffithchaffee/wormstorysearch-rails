FactoryBot.define do
  factory(:questionablequesting_story) do
    story { FactoryBot.create(:story) }
    title { FactoryBot.generate(:uniq_s) }
    location_id { FactoryBot.generate(:uniq_s) }
    location_path { location_id ? "/#{location_id}" : "/#{FactoryBot.generate(:uniq_s)}" }
    author_name { FactoryBot.generate(:uniq_s) }
    word_count { rand(0..2_500_000) }
    story_updated_at { FactoryBot.generate(:time_in_past) }
    story_created_on { (story_updated_at || FactoryBot.generate(:date_in_past)) - rand(0..5).days }
  end
end
