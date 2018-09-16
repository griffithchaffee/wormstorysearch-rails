class FanfictionStory::Test < ApplicationRecord::TestCase

  include LocationStoryConcern::TestConcern

  testing "read_url" do
    story = FactoryBot.create(factory)
    assert_equal("FanFiction", story.const.location_label)
    assert_equal("https://www.fanfiction.net", story.const.location_host)
    # no chapters
    assert_equal(story.location_url, story.read_url)
    # add chapter
    new_chapter = FactoryBot.create("#{factory}_chapter", story: story)
    assert_equal(story.reload.read_url, new_chapter.location_url)
  end

  testing "update_rating!" do
    location_story = FactoryBot.create(factory)
    story = location_story.story
    # after_save update story rating
    location_story.update!(favorites: 30)
    # story rating should be updated
    assert_equal(location_story.rating, story.reload.rating)
  end

  testing "crossover_for_story" do
    {
      "Worm & Z Nation " => "Z Nation",
      "Worm & iZombie"   => "iZombie",
      "X-Com"            => "X-Com",
      "X-Com & Worm"     => "X-Com",
      "X-overs"          => nil,
      "X-overs & Worm"   => nil,
      "Yandere Simulator" => "Yandere Simulator",
      "Young Justice & Worm" => "Young Justice",
      "Yuki Yuna is a Hero/結城友奈は勇者である" => "Yuki Yuna is a Hero",
    }.each do |crossover, formatted_crossover|
      assert_same(
        formatted_crossover,
        FactoryBot.build(factory, crossover: crossover).crossover_for_story,
        crossover
      )
    end
  end

end
