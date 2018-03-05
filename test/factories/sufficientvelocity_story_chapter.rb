FactoryGirl.define do
  factory(:sufficientvelocity_story_chapter) do
    story { FactoryGirl.create(:sufficientvelocity_story) }
    title { FactoryGirl.generate(:uniq_s) }
    position { FactoryGirl.generate(:uniq_i) }
    location_path { "/#{position}" }
    chapter_updated_at { story && story.story_updated_at ? story.story_updated_at : FactoryGirl.generate(:time_in_past) }
    chapter_created_on { story && story.story_created_on ? story.story_created_on : FactoryGirl.generate(:date_in_past) }
  end
end
