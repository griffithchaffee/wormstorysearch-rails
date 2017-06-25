FactoryGirl.define do
  factory(:story) do
    a = 1
    title { FactoryGirl.generate(:uniq_s) }
    location { Story.const.locations.map(&:location).sample }
    location_story_id { location ? "#{location}-#{FactoryGirl.generate(:uniq_i)}" : FactoryGirl.generate(:uniq_s) }
    location_path { location_story_id ? "/#{location_story_id}" : "/#{FactoryGirl.generate(:uniq_s)}" }
    author { FactoryGirl.generate(:uniq_s) }
    word_count { rand(0..2_000_000) }
    story_created_on { FactoryGirl.generate(:date_in_past) }
    story_updated_at { FactoryGirl.generate(:time_in_past) }
  end
end
