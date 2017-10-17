class StoryAuthor::Test < ApplicationRecord::TestCase

  testing "location_names and name autoset" do
    author = FactoryGirl.create(:story_author)
    original_name = author.name
    location_names = []
    # changing location names with a custom name
    Story.const.location_models.each.with_index do |location_model, i|
      location_name = "#{location_model.const.location_slug}_name"
      location_names << location_name
      author.update!("#{location_model.const.location_slug}_name" => location_name)
    end
    assert_equal(location_names, author.location_names)
    assert_equal(original_name, author.name)
    author.update!(name: nil)
    assert_equal(location_names.join(" / "), author.name)
    # changing location names keep name in sync
    Story.const.location_models.each.with_index do |location_model, i|
      author.update!("#{location_model.const.location_slug}_name" => "index #{i}")
      assert_equal(author.location_names.join(" / "), author.name)
    end
  end

  Story.const.location_models.each do |location_model|
    testing "#{location_model} story auto creates author" do
      location_story = FactoryGirl.create("#{location_model.const.location_slug}_story", author_name: "SMITH")
      author = location_story.reload.author
      author.attributes.each do |attribute, value|
        next if attribute.in?(%w[ created_at updated_at id ])
        if attribute.in?(["name", "#{location_model.const.location_slug}_name"])
          assert_equal("SMITH", value, "author.#{attribute}")
        else
          assert_nil(value, "author.#{attribute}")
        end
      end
    end
  end

end
