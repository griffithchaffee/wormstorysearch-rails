FactoryGirl.define do
  factory(:spacebattles_story) do
    title { FactoryGirl.generate(:uniq_s) }
    location_story_id { FactoryGirl.generate(:uniq_s) }
    location_path { location_story_id ? "/#{location_story_id}" : "/#{FactoryGirl.generate(:uniq_s)}" }
    author { FactoryGirl.generate(:uniq_s) }
    word_count { rand(0..2_500_000) }
    story_updated_at { FactoryGirl.generate(:time_in_past) }
    story_created_on { (story_updated_at || FactoryGirl.generate(:date_in_past)) - rand(0..5).days }
  end
end
