class LocationSearcher::SufficientvelocitySearcher::Test < ApplicationTestCase

  testing "stories" do
    searcher = LocationSearcher::SufficientvelocitySearcher.new
    stories_html = File.read(File.expand_path("../pages/sufficientvelocity_stories.html", __FILE__))
    stories_html = SiteCrawler::HtmlParser.parse(stories_html)
    # parse stories
    results = searcher.update_stories_from_html!(stories_html, chapters: false)
    assert_equal(true, results[:more])
    assert_equal([9, 9, 9], [results[:stories].size, SufficientvelocityStory.count, Story.count])
    # verify a story
    sufficientvelocity_story = SufficientvelocityStory.first
    assert_equal(
      {
        "author"=>"UnwelcomeStorm",
        "average_chapter_likes"=>"0.0",
        "category"=>"story",
        "is_locked"=>"false",
        "location_id"=>"thread-31091",
        "location_path"=>"/threads/constellations-worm-okami.31091",
        "read_url"=>"https://forums.sufficientvelocity.com/threads/constellations-worm-okami.31091",
        "story_created_on"=>"2016-08-11",
        "story_updated_at"=>"2016-08-11 00:00:00 -0700",
        "title"=>"Constellations (Worm/Okami)",
        "word_count"=>"110000"
      }.sort.to_h,
      sufficientvelocity_story.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    # parse story chapters
    chapters_html = File.read(File.expand_path("../pages/sufficientvelocity_story_chapters.html", __FILE__))
    chapters_html = SiteCrawler::HtmlParser.parse(chapters_html)
    searcher.update_chapters_for_story_from_html!(sufficientvelocity_story, chapters_html)
    assert_equal(44, sufficientvelocity_story.chapters.count)
    chapter = sufficientvelocity_story.chapters.first
    assert_equal(
      {
        "category"=>"chapter",
        "chapter_created_on"=>"2016-08-11",
        "chapter_updated_at"=>"2016-08-11 00:00:00 -0700",
        "likes"=>"0",
        "location_path"=>"/threads/constellations-worm-okami.31091/",
        "position"=>"1",
        "title"=>"Chapter 1",
        "word_count"=>"1700"
      }.sort.to_h,
      chapter.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
  end

  testing "quests" do
    searcher = LocationSearcher::SufficientvelocitySearcher.new
    stories_html = File.read(File.expand_path("../pages/sufficientvelocity_quests.html", __FILE__))
    stories_html = SiteCrawler::HtmlParser.parse(stories_html)
    # parse stories
    results = searcher.update_stories_from_html!(stories_html, attributes: { category: "quest" }, chapters: false)
    assert_equal(true, results[:more])
    assert_equal([4, 4, 4], [results[:stories].size, SufficientvelocityStory.count, Story.count])
    # verify a story
    sufficientvelocity_story = SufficientvelocityStory.first
    assert_equal(
      {
        "author"=>"NIV3K",
        "average_chapter_likes"=>"0.0",
        "category"=>"quest",
        "is_locked"=>"false",
        "location_id"=>"thread-39656",
        "location_path"=>"/threads/life-and-times-of-a-teenage-vampire-worm-v-tr-quest.39656",
        "read_url"=>"https://forums.sufficientvelocity.com/threads/life-and-times-of-a-teenage-vampire-worm-v-tr-quest.39656",
        "story_created_on"=>"2017-06-28",
        "story_updated_at"=>"2017-06-28 06:00:17 -0700",
        "title"=>"Life and Times of a Teenage Vampire (Worm/V:tR Quest)",
        "word_count"=>"4500"
      }.sort.to_h,
      sufficientvelocity_story.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    # parse story chapters
    chapters_html = File.read(File.expand_path("../pages/sufficientvelocity_quest_chapters.html", __FILE__))
    chapters_html = SiteCrawler::HtmlParser.parse(chapters_html)
    searcher.update_chapters_for_story_from_html!(sufficientvelocity_story, chapters_html)
    assert_equal(3, sufficientvelocity_story.chapters.count)
    chapter = sufficientvelocity_story.chapters.first
    assert_equal(
      {
        "category"=>"chapter",
        "chapter_created_on"=>"2017-06-28",
        "chapter_updated_at"=>"2017-06-28 06:00:17 -0700",
        "likes"=>"0",
        "location_path"=>"/threads/life-and-times-of-a-teenage-vampire-worm-v-tr-quest.39656/",
        "position"=>"1",
        "title"=>"1.1",
        "word_count"=>"860"
      }.sort.to_h,
      chapter.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
  end

end
