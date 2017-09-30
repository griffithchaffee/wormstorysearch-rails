class LocationSearcher::FanfictionSearcher::Test < ApplicationTestCase

  testing "stories" do
    searcher = LocationSearcher::FanfictionSearcher.new
    stories_html = File.read(File.expand_path("../pages/fanfiction_stories.html", __FILE__))
    stories_html = SiteCrawler::HtmlParser.parse(stories_html)
    # parse stories
    results = searcher.update_stories_from_html!(stories_html, chapters: false)
    assert_equal(true, results[:more])
    assert_equal([25, 25, 25], [results[:stories].size, FanfictionStory.count, Story.count])
    # verify a story
    fanfiction_story = FanfictionStory.first
    assert_equal(
      {
        "author"=>"Racheakt",
        "category"=>"story",
        "crossover"=>"",
        "description"=>"Part 1 of the Bird Series. Taylor triggers and is sent to an insane asylum.",
        "favorites"=>"154",
        "favorites_updated_at"=>fanfiction_story.attributes["favorites_updated_at"].to_s.presence,
        "is_locked"=>"false",
        "location_id"=>"12337359",
        "location_path"=>"/s/12337359/1/Cage",
        "read_url"=>"https://www.fanfiction.net/s/12337359/1/Cage",
        "status"=>"ongoing",
        "story_created_on"=>"2017-01-25",
        "story_updated_at"=>"2017-07-02 12:48:41 -0700",
        "title"=>"Cage",
        "word_count"=>"74610"
      }.sort.to_h,
      fanfiction_story.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    # parse story chapters
    chapters_html = File.read(File.expand_path("../pages/fanfiction_story_chapters.html", __FILE__))
    chapters_html = SiteCrawler::HtmlParser.parse(chapters_html)
    searcher.update_chapters_for_story_from_html!(fanfiction_story, chapters_html)
    assert_equal(32, fanfiction_story.chapters.count)
    chapter = fanfiction_story.chapters.first
    assert_equal(
      {
        "category"=>"chapter",
        "chapter_created_on"=>"2017-01-25",
        "chapter_updated_at"=>"2017-01-25 00:00:00 -0800",
        "location_path"=>"/s/12337359/1/Cage",
        "position"=>"1",
        "title"=>"Cygnet 1-1",
        "word_count"=>"0"
      }.sort.to_h,
      chapter.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
  end

  testing "crossovers" do
    searcher = LocationSearcher::FanfictionSearcher.new
    stories_html = File.read(File.expand_path("../pages/fanfiction_crossover_stories.html", __FILE__))
    stories_html = SiteCrawler::HtmlParser.parse(stories_html)
    # parse stories
    results = searcher.update_stories_from_html!(stories_html, chapters: false)
    assert_equal(true, results[:more])
    assert_equal([25, 25, 25], [results[:stories].size, FanfictionStory.count, Story.count])
    # verify a story
    fanfiction_story = FanfictionStory.first
    assert_equal(
      {
        "author"=>"Rhydeble",
        "category"=>"story",
        "crossover"=>"Dresden Files & Worm",
        "description"=>
         "Leviathan has destroyed Brockton Bay, and Taylor Hebert has lost everything she had. Now, as a teenage refugee in Chicago, she is trying to rebuild a life for herself as a vigilante. However, everything in Chicago is not as it seems, and parahuman supervillains fight side by side with vampires. And that hero guy, Myrddin? He claims he's actually a wizard called Harry Dresden.",
        "favorites"=>"221",
        "favorites_updated_at"=>fanfiction_story.attributes["favorites_updated_at"].to_s.presence,
        "is_locked"=>"false",
        "location_id"=>"12347484",
        "location_path"=>"/s/12347484/1/Of-Wasps-and-Wizards",
        "read_url"=>"https://www.fanfiction.net/s/12347484/1/Of-Wasps-and-Wizards",
        "status"=>"ongoing",
        "story_created_on"=>"2017-02-01",
        "story_updated_at"=>"2017-07-01 10:56:43 -0700",
        "title"=>"Of Wasps and Wizards",
        "word_count"=>"95902"
      }.sort.to_h,
      fanfiction_story.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    # parse story chapters
    chapters_html = File.read(File.expand_path("../pages/fanfiction_crossover_story_chapters.html", __FILE__))
    chapters_html = SiteCrawler::HtmlParser.parse(chapters_html)
    searcher.update_chapters_for_story_from_html!(fanfiction_story, chapters_html)
    assert_equal(38, fanfiction_story.chapters.count)
    chapter = fanfiction_story.chapters.first
    assert_equal(
      {
        "category"=>"chapter",
        "chapter_created_on"=>"2017-02-01",
        "chapter_updated_at"=>"2017-02-01 00:00:00 -0800",
        "location_path"=>"/s/12347484/1/Of-Wasps-and-Wizards",
        "position"=>"1",
        "title"=>"Chapter 1",
        "word_count"=>"0"
      }.sort.to_h,
      chapter.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
  end
end
