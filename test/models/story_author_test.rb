class StoryAuthor::Test < ApplicationRecord::TestCase

  testing "before_validation name autoset" do
    author = FactoryBot.create(:story_author)
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
  end

  Story.const.location_models.each do |location_model|
    testing "#{location_model} story auto creates author" do
      location_story = FactoryBot.create("#{location_model.const.location_slug}_story", author_name: "SMITH")
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

  testing "location_name change updates story authors" do
    story = FactoryBot.create(:story)
    original_author = story.author
    spacebattles_story = FactoryBot.create(:spacebattles_story, story: story, author_name: original_author.spacebattles_name)
    assert_equal([1, 1], [Story.count, StoryAuthor.count])
    new_author = FactoryBot.create(:story_author)
    # remove duplicate author
    original_author.destroy!
    new_author.update!(spacebattles_name: original_author.spacebattles_name)
    # attached stories should update thier authors
    assert_equal(new_author.id, story.reload.author_id)
  end

  testing "merge_with_author" do
    # setup primary
    primary_author = FactoryBot.create(:story_author)
    primary_story  = FactoryBot.create(:story, author: primary_author)
    primary_spacebattles_story = FactoryBot.create(
      :spacebattles_story,
      story: primary_story,
      author_name: primary_author.spacebattles_name
    )
    # setup duplicates
    duplicate_author = FactoryBot.create(:story_author)
    duplicate_story  = FactoryBot.create(:story, author: duplicate_author)
    duplicate_sufficientvelocity_story = FactoryBot.create(
      :sufficientvelocity_story,
      story: duplicate_story,
      author_name: duplicate_author.sufficientvelocity_name
    )
    duplicate_fanfiction_story = FactoryBot.create(
      :fanfiction_story,
      story: duplicate_story,
      author_name: duplicate_author.fanfiction_name
    )
    duplicate_archiveofourown_story = FactoryBot.create(
      :archiveofourown_story,
      story: duplicate_story,
      author_name: duplicate_author.archiveofourown_name
    )
    # merge with different spacebattles_name
    primary_author.update!(fanfiction_name: nil)
    primary_author.merge_with_author!(duplicate_author)
    assert_equal(false, duplicate_author.destroyed?)
    assert_same(nil, duplicate_author.fanfiction_name)
    assert_equal(duplicate_fanfiction_story.author_name, primary_author.fanfiction_name)
    assert_equal(primary_author, duplicate_fanfiction_story.reload.story.author)
    # merge with destroy
    duplicate_author.update!(spacebattles_name: nil, archiveofourown_name: nil, questionablequesting_name: nil)
    primary_author.update!(sufficientvelocity_name: nil)
    primary_author.reload.merge_with_author!(duplicate_author.reload)
    assert_equal(true, duplicate_author.destroyed?)
    assert_equal(duplicate_sufficientvelocity_story.author_name, primary_author.sufficientvelocity_name)
    assert_equal(primary_author, duplicate_sufficientvelocity_story.reload.story.author)
  end

end
