module LocationStoryConcern::TestConcern
  extend ActiveSupport::Concern

  included do
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
      story.update!(story_updated_at: 1.day.ago)
      assert_equal(1.day.ago.to_i, story.story_updated_at.to_i)
      # accessor for latest updated_at
      assert_equal(chapter.chapter_updated_at.to_i, story.story_updated_at!.to_i)
      # chapter updated
      chapter.update!(chapter_updated_at: 6.hours.ago)
      assert_equal(chapter.chapter_updated_at.to_i, story.reload.story_updated_at.to_i)
      # locked story
      story.update!(is_locked: true)
      locked_updated_at = story.story_updated_at
      chapter.update!(chapter_updated_at: 3.hours.ago)
      assert_equal(locked_updated_at.to_i, story.reload.story_updated_at.to_i)
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
      # locked story
      story.update!(is_locked: true)
      locked_updated_at = story.story_updated_at
      location_story.update!(story_updated_at: 6.hours.ago)
      assert_equal(locked_updated_at.to_i, story.reload.story_updated_at.to_i)
    end

    testing "default parse_crossover_from_title" do
      {
        "The Nightmare Queen (Worm/RotG)" => "RotG",
        "Traversing Paths (Spin-Off of Hyperdimension Taylor)" => "Spin-Off of Hyperdimension",
        "A Tailored Future - Power Overwhelming (AltPower!Taylor, MinorMarvelXoverElement)" => "MinorMarvelXoverElement",
        "Of Wasps and Wizards [Worm|Dresden Files] [Fusion]" => "Dresden Files",
        "Terminus [Worm AU]" => nil,
        "Reincarnation of an Angel [Worm Quest]" => nil,
      }.each do |title, crossover|
        assert_same(crossover, FactoryGirl.build(factory).parse_crossover_from_title(title), title)
      end
    end

    testing "story!" do
      location_story = FactoryGirl.create(factory, story: nil, title: "Well Traveled [Worm](Planeswalker Taylor)")
      # creates story
      story = location_story.story!
      assert_equal(true, story.saved?)
      assert_equal("Well Traveled", story.title, story.inspect)
      if location_story.try(:crossover)
        assert_equal(location_story.crossover, story.crossover, story.inspect)
      else
        assert_equal("Planeswalker", story.crossover, story.inspect)
      end
      # finds existing story
      assert_equal(story, location_story.story!)
    end
  end
end
