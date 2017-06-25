FactoryGirl.define do
  factory(:story_chapter) do
    story { FactoryGirl.create(:story) }
    title { FactoryGirl.generate(:uniq_s) }
    position { FactoryGirl.generate(:uniq_i) }
    location_path { "/#{position}" }
    chapter_created_at { 3.hours.ago }
    chapter_updated_at { 3.hours.ago }
  end
end
