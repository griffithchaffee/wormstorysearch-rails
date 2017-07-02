FactoryGirl.define do
  factory(:story) do
    title { FactoryGirl.generate(:uniq_s) }
    author { FactoryGirl.generate(:uniq_s) }
    word_count { rand(0..2_000_000) }
    story_created_on { FactoryGirl.generate(:date_in_past) }
    story_updated_at { FactoryGirl.generate(:time_in_past) }
  end
end
