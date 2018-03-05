class ArchiveofourownStory::Test < ApplicationRecord::TestCase

  include LocationStoryConcern::TestConcern

  testing "read_url" do
    story = FactoryGirl.create(factory)
    assert_equal("Archive of Our Own", story.const.location_label)
    assert_equal("http://archiveofourown.org", story.const.location_host)
    # no chapters
    assert_equal(story.location_url, story.read_url)
    # add chapter
    FactoryGirl.create("#{factory}_chapter", story: story)
    assert_equal(story.location_url, story.reload.read_url)
  end

  testing "update_rating!" do
    location_story = FactoryGirl.create(factory)
    story = location_story.story
    # after_save update story rating
    location_story.update!(kudos: 30)
    # story rating should be updated
    assert_equal(location_story.rating, story.reload.rating)
  end

  testing "crossover_for_story" do
    {
      "The Lord of the Rings - J. R. R. Tolkien" => "The Lord of the Rings",
      "The Secret World"                         => "The Secret World",
      "Thor (Movies)"                            => "Thor",
      "Top wo Nerae 2! Diebuster"                => "Top wo Nerae 2! Diebuster",
      "Transformers - All Media Types"           => "Transformers",
      "Tru Calling"                              => "Tru Calling",
      "Twig - Wildbow"                           => "Twig",
      "Worm (Web Serial Novel)"                  => nil,
      "Worm - Fandom"                            => nil,
      "XCOM (Video Games) & Related Fandoms"     => "XCOM",
      "더 게이머 | The Gamer (Webcomic)"         => "The Gamer",
      "Xī yóu jì | Journey to the West - Wú Cheng'en" => "Journey to the West",
      "クロスアンジュ 天使と竜の輪舞 | Cross Ange: Rondo of Angels and Dragons"    => "Cross Ange: Rondo of Angels and Dragons",
      "ジョジョの奇妙な冒険 | JoJo no Kimyou na Bouken | JoJo's Bizarre Adventure" => "JoJo's Bizarre Adventure",
    }.each do |crossover, formatted_crossover|
      assert_same(
        formatted_crossover,
        FactoryGirl.build(factory, crossover: crossover).crossover_for_story,
        crossover
      )
    end
  end

end
