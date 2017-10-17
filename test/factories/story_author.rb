FactoryGirl.define do
  factory(:story_author) do
    name { FactoryGirl.generate(:uniq_s) }
    Story.const.location_models.each do |location_model|
      send("#{location_model.const.location_slug}_name") { FactoryGirl.generate(:uniq_s) }
    end
  end
end
