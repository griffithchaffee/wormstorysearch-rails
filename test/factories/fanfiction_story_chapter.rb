FactoryBot.define do
  factory(:fanfiction_story_chapter) do
    story { FactoryBot.create(:fanfiction_story) }
    title { FactoryBot.generate(:uniq_s) }
    position { FactoryBot.generate(:uniq_i) }
    location_path { "/#{position}" }
    chapter_updated_at { story && story.story_updated_at ? story.story_updated_at : FactoryBot.generate(:time_in_past) }
    chapter_created_on { story && story.story_created_on ? story.story_created_on : FactoryBot.generate(:date_in_past) }
  end
end
