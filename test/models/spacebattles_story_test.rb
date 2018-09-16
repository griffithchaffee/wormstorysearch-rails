class SpacebattlesStory::Test < ApplicationRecord::TestCase

  include LocationStoryConcern::TestConcern

  testing "read_url" do
    story = FactoryBot.create(factory)
    assert_equal("SpaceBattles", story.const.location_label)
    assert_equal("https://forums.spacebattles.com", story.const.location_host)
    # no chapters
    assert_equal(story.location_url, story.read_url)
    # add chapter
    FactoryBot.create("#{factory}_chapter", story: story)
    assert_equal("#{story.location_url}/threadmarks", story.reload.read_url)
  end

  testing "update_rating!" do
    location_story = FactoryBot.create(factory, story_created_on: 1.month.ago, story_updated_at: 1.month.ago)
    story = location_story.story
    valid_chapter1  = FactoryBot.create("#{factory}_chapter", story: location_story, chapter_created_on: 1.month.ago, chapter_updated_at: 1.week.ago, likes: 10)
    valid_chapter2  = FactoryBot.create("#{factory}_chapter", story: location_story, chapter_created_on: 1.month.ago, chapter_updated_at: 1.week.ago, likes: 20)
    new_chapter     = FactoryBot.create("#{factory}_chapter", story: location_story, chapter_created_on: 1.day.ago, chapter_updated_at: 1.hour.ago)
    unliked_chapter = FactoryBot.create("#{factory}_chapter", story: location_story, chapter_created_on: 1.month.ago, chapter_updated_at: 1.week.ago, likes: 0)
    omake_chapter   = FactoryBot.create("#{factory}_chapter", story: location_story, chapter_created_on: 1.month.ago, chapter_updated_at: 1.week.ago, category: "omake")
    # after_save update location_story rating
    assert_equal([20, 15.0], [location_story.highest_chapter_likes, location_story.average_chapter_likes])
    # story rating should be updated
    assert_equal(location_story.rating, story.reload.rating)
  end

  testing "crossover_for_story" do
    {
      "Terminus [Worm AU]"                     => nil,
      "Reincarnation of an Angel [Worm Quest]" => nil,
      "The Nightmare Queen (Worm/RotG)"        => "RotG",
      "The Nightmare Queen (Worm & RotG)"      => "RotG",
      "The Nightmare Queen (WormXRotG)"        => "RotG",
      "Traversing Paths (Spin-Off of Hyperdimension Taylor)" => "Spin-Off of Hyperdimension",
      "Of Wasps and Wizards [Worm|Dresden Files] [Fusion]"   => "Dresden Files",
      "A Tailored Future - Power Overwhelming (AltPower!Taylor, MinorMarvelXoverElement)" => "MinorMarvelXoverElement",
    }.each do |title, formatted_crossover|
      assert_same(
        formatted_crossover,
        FactoryBot.build(factory, title: title).crossover_for_story,
        title
      )
    end
  end

end
