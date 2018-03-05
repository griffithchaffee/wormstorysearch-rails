module LocationStoryConcern::TestConcern
  extend ActiveSupport::Concern

  included do
    testing "chapters inverse_of story" do
      story = FactoryGirl.create(factory)
      chapter = FactoryGirl.create("#{factory}_chapter", story: story)
      assert_equal(true, story.reload.chapters.load.first.story.equal?(story))
    end

    testing "title description crossover normalization" do
      story = FactoryGirl.create(factory)
      %w[ title description crossover ].each do |attribute|
        next if !attribute.in?(story.class.column_names)
        story.update!(attribute => " \n\r MULTI  #{attribute}   VALUE \n\r ")
        assert_equal("MULTI #{attribute} VALUE", story.send(attribute))
      end
    end

    testing "word_count" do
      story = FactoryGirl.create(factory)
      {
        "123" => 123,
        "1.1k" => 1100, "1.25k" => 1250,
        "1.1m" => 1100000, "1.25m" => 1250000,
      }.each do |word_count_s, word_count|
        story.update!(word_count: word_count_s)
        assert_equal(word_count, story.word_count, "#{word_count_s}")
      end
    end

    testing "story_updated_at autoset in chapter after_save" do
      story = FactoryGirl.create(factory)
      chapter = FactoryGirl.create("#{factory}_chapter", story: story, chapter_updated_at: 1.hour.ago)
      # story should be updated when chapter created
      assert_equal(chapter.chapter_updated_at.to_i, story.reload.story_updated_at.to_i)
      # story can have updated_at changed
      story.update!(story_updated_at: Date.yesterday.to_time)
      assert_equal(Date.yesterday.to_i, story.story_updated_at.to_i)
      # accessor for latest updated_at
      assert_equal(chapter.chapter_updated_at.to_i, story.story_updated_at!.to_i)
      # chapter updated
      chapter.update!(chapter_updated_at: 6.hours.ago)
      assert_equal(chapter.chapter_updated_at.to_i, story.reload.story_updated_at.to_i)
    end

    testing "story.story_updated_at autoset in after_save" do
      location_story = FactoryGirl.create(factory, story: nil, story_updated_at: 10.hours.ago)
      story = location_story.story!
      story.update!(story_created_on: 12.hours.ago, story_updated_at: 12.hours.ago)
      # story_id change
      location_story.update!(story: story)
      assert_equal(location_story.story_updated_at.to_i, story.reload.story_updated_at.to_i)
      # story_updated_at change
      location_story.update!(story_updated_at: 8.hours.ago)
      assert_equal(location_story.story_updated_at.to_i, story.reload.story_updated_at.to_i)
    end

    testing "story!" do
      location_story = FactoryGirl.create(factory, story: nil, title: "Well Traveled [Worm](Planeswalker Taylor)")
      assert_nil(location_story.story)
      # creates story with attributes
      story = location_story.story!
      assert_equal([Story.first, location_story.author_name], [story, story.author.name])
      assert_equal("Well Traveled", story.title)
      if location_story.try(:crossover)
        assert_equal(location_story.crossover, story.crossover)
      else
        assert_equal("Planeswalker", story.crossover)
      end
      # story unset
      assert_nil(location_story.story)
      # finds existing matching story
      assert_equal(story, location_story.story!)
      # returns associated story if present
      location_story.update!(story: story)
      assert_equal(true, location_story.story.equal?(location_story.story!))
      # no existing story
      story.update!(title: "abc 123")
      assert_equal(true, location_story.story!(return_associated_story: false, create_new_story: false).unsaved?)
      # exact title match
      location_story.update!(title: "ABC 123")
      assert_equal(story, location_story.story!(return_associated_story: false))
      # parse_title fuzzy match
      location_story.update!(title: "ABC [Worm] (Crossover)")
      assert_equal(story, location_story.story!(return_associated_story: false))
      # author must match
      story.author.update!("#{location_story.const.location_slug}_name" => "NEW")
      assert_equal(true, location_story.story!(return_associated_story: false, create_new_story: false).unsaved?)
      location_story.update!(author_name: "NEW")
      assert_equal(story, location_story.story!(return_associated_story: false))
      # make sure find_existing_story works
      assert_equal(true, location_story.story!(return_associated_story: false, find_existing_story: false, create_new_story: false).unsaved?)
    end
  end
end
