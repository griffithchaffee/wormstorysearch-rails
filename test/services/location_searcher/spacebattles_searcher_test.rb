class LocationSearcher::SpacebattlesSearcher::Test < ApplicationTestCase

  testing "stories" do
    searcher = LocationSearcher::SpacebattlesSearcher.new
    stories_html = File.read(File.expand_path("../pages/spacebattles_stories.html", __FILE__))
    stories_html = SiteCrawler::HtmlParser.parse(stories_html)
    # parse stories
    results = searcher.update_stories_from_html!(stories_html, is_worm_story: true, chapters: false)
    assert_equal(true, results[:more])
    assert_equal([30, 30, 30], [results[:stories].size, SpacebattlesStory.count, Story.count])
    # verify a story
    spacebattles_story = SpacebattlesStory.first
    assert_equal(
      {
        "author"=>"Dyngari",
        "average_chapter_likes"=>"0.0",
        "category"=>"story",
        "is_locked"=>"false",
        "location_id"=>"thread-536881",
        "location_path"=>"/threads/aggregation-worm-factorio-oc.536881",
        "read_url"=>"https://forums.spacebattles.com/threads/aggregation-worm-factorio-oc.536881",
        "story_created_on"=>"2017-06-17",
        "story_updated_at"=>"2017-06-17 00:00:00 -0700",
        "title"=>"Aggregation [Worm/Factorio][OC]",
        "word_count"=>"4200",
      }.sort.to_h,
      spacebattles_story.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    # parse story chapters
    chapters_html = File.read(File.expand_path("../pages/spacebattles_story_chapters.html", __FILE__))
    chapters_html = SiteCrawler::HtmlParser.parse(chapters_html)
    searcher.update_chapters_for_story_from_html!(spacebattles_story, chapters_html)
    assert_equal(6, spacebattles_story.chapters.count)
    chapter = spacebattles_story.chapters.first
    assert_equal(
      {
        "chapter_created_on"=>"2017-06-17",
        "chapter_updated_at"=>"2017-06-17 00:00:00 -0700",
        "likes"=>"0",
        "position"=>"1",
        "word_count"=>"390",
        "category"=>"chapter",
        "location_path"=>"/threads/aggregation-worm-factorio-oc.536881/",
        "title"=>"Prologue"
      }.sort.to_h,
      chapter.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
  end

  testing "quests" do
    searcher = LocationSearcher::SpacebattlesSearcher.new
    stories_html = File.read(File.expand_path("../pages/spacebattles_quests.html", __FILE__))
    stories_html = SiteCrawler::HtmlParser.parse(stories_html)
    # parse stories
    results = searcher.update_stories_from_html!(stories_html, attributes: { category: "quest" }, chapters: false)
    assert_equal(true, results[:more])
    assert_equal([2, 2, 2], [results[:stories].size, SpacebattlesStory.count, Story.count])
    # verify a story
    spacebattles_story = SpacebattlesStory.first
    assert_equal(
      {
        "author"=>"Crimson Square",
        "average_chapter_likes"=>"0.0",
        "category"=>"quest",
        "is_locked"=>"false",
        "location_id"=>"thread-532675",
        "location_path"=>"/threads/reincarnation-of-an-angel-worm-quest.532675",
        "read_url"=>"https://forums.spacebattles.com/threads/reincarnation-of-an-angel-worm-quest.532675",
        "story_created_on"=>"2017-06-05",
        "story_updated_at"=>"2017-06-05 00:00:00 -0700",
        "title"=>"Reincarnation of an Angel [Worm Quest]",
        "word_count"=>"34000"
      }.sort.to_h,
      spacebattles_story.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    # parse story chapters
    chapters_html = File.read(File.expand_path("../pages/spacebattles_quest_chapters.html", __FILE__))
    chapters_html = SiteCrawler::HtmlParser.parse(chapters_html)
    searcher.update_chapters_for_story_from_html!(spacebattles_story, chapters_html)
    assert_equal(12, spacebattles_story.chapters.count)
    chapter = spacebattles_story.chapters.first
    assert_equal(
      {
        "category"=>"chapter",
        "chapter_created_on"=>"2017-06-05",
        "chapter_updated_at"=>"2017-06-05 00:00:00 -0700",
        "likes"=>"0",
        "location_path"=>"/threads/reincarnation-of-an-angel-worm-quest.532675/",
        "position"=>"1",
        "title"=>"Character Creation - 1.1",
        "word_count"=>"1000"
      }.sort.to_h,
      chapter.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
  end

end
