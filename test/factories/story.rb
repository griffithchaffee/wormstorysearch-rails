FactoryGirl.define do
  factory(:story) do
    title { FactoryGirl.generate(:uniq_s) }
    word_count { rand(0..2_000_000) }
    author { FactoryGirl.create(:story_author) }
    story_created_on { FactoryGirl.generate(:date_in_past) }
    story_updated_at { FactoryGirl.generate(:time_in_past) }
    is_locked { false }
  end
end
