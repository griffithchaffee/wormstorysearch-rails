class LocationSearcher::QuestionablequestingSearcher::Test < ApplicationTestCase

  testing "sfw stories" do
    searcher = LocationSearcher::QuestionablequestingSearcher.new
    stories_html = File.read(File.expand_path("../pages/questionablequesting_sfw_stories.html", __FILE__))
    stories_html = SiteCrawler::HtmlParser.parse(stories_html)
    # parse stories
    results = searcher.update_stories_from_html!(stories_html, chapters: false)
    assert_equal(true, results[:more])
    assert_equal([6, 6, 6], [results[:stories].size, QuestionablequestingStory.count, Story.count])
    # verify a story
    questionablequesting_story = QuestionablequestingStory.all.sort.second
    assert_equal(
      {
        "author_name"=>"TCGM",
        "average_chapter_likes"=>"0.0",
        "category"=>"story",
        "clicks"=>"0",
        "highest_chapter_likes"=>"0",
        "is_nsfw"=>"false",
        "location_id"=>"thread-7044",
        "location_path"=>"/threads/i-am-ziz-worm-si-simurgh.7044",
        "read_url"=>
         "https://forum.questionablequesting.com/threads/i-am-ziz-worm-si-simurgh.7044",
        "story_created_on"=>"2018-02-04",
        "story_updated_at"=>"2018-02-04 00:00:00 -0800",
        "title"=>"I Am Ziz [Worm SI!Simurgh]",
        "word_count"=>"0"
      }.sort.to_h,
      questionablequesting_story.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    # parse story chapters
    chapters_html = File.read(File.expand_path("../pages/questionablequesting_sfw_story_chapters.html", __FILE__))
    chapters_html = SiteCrawler::HtmlParser.parse(chapters_html)
    searcher.update_chapters_for_story_from_html!(questionablequesting_story, chapters_html)
    assert_equal(3, questionablequesting_story.chapters.count)
    chapter = questionablequesting_story.chapters.sort.first
    assert_equal(
      {
        "category"=>"chapter",
        "chapter_created_on"=>"2018-02-04",
        "chapter_updated_at"=>"2018-02-04 20:55:33 -0800",
        "likes"=>"177",
        "location_path"=>"/threads/i-am-ziz-worm-si-simurgh.7044/",
        "position"=>"1",
        "title"=>"Chapter 1 - Entry, Re-Entry, Entrance",
        "word_count"=>"1968"
      }.sort.to_h,
      chapter.attributes.except(*%w[ id story_id created_at updated_at likes_updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    assert_equal(4065, questionablequesting_story.word_count)
  end

  testing "nsfw stories" do
    searcher = LocationSearcher::QuestionablequestingSearcher.new
    stories_html = File.read(File.expand_path("../pages/questionablequesting_nsfw_stories.html", __FILE__))
    stories_html = SiteCrawler::HtmlParser.parse(stories_html)
    # parse stories
    results = searcher.update_stories_from_html!(stories_html, attributes: { is_nsfw: true }, chapters: false)
    assert_equal(true, results[:more])
    assert_equal([5, 5, 5], [results[:stories].size, QuestionablequestingStory.count, Story.count])
    # verify a story
    questionablequesting_story = QuestionablequestingStory.all.sort.third
    assert_equal(
      {
        "author_name"=>"Lunahaile",
        "average_chapter_likes"=>"0.0",
        "category"=>"story",
        "clicks"=>"0", "highest_chapter_likes"=>"0",
        "is_nsfw"=>"true",
        "location_id"=>"thread-7074",
        "location_path"=>"/threads/ah-fuck-it-im-hungry-worm-cyoa-si.7074",
        "read_url"=>"https://forum.questionablequesting.com/threads/ah-fuck-it-im-hungry-worm-cyoa-si.7074",
        "story_created_on"=>"2018-02-10",
        "story_updated_at"=>"2018-02-10 00:00:00 -0800",
        "title"=>"Ah Fuck It, I'm Hungry. (Worm CYOA/SI)",
        "word_count"=>"0"
      }.sort.to_h,
      questionablequesting_story.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    # parse story chapters
    chapters_html = File.read(File.expand_path("../pages/questionablequesting_nsfw_story_chapters.html", __FILE__))
    chapters_html = SiteCrawler::HtmlParser.parse(chapters_html)
    searcher.update_chapters_for_story_from_html!(questionablequesting_story, chapters_html)
    assert_equal(4, questionablequesting_story.chapters.count)
    chapter = questionablequesting_story.chapters.sort.last
    assert_equal(
      {
        "category"=>"chapter",
        "chapter_created_on"=>"2018-08-15",
        "chapter_updated_at"=>"2018-08-15 17:51:04 -0700",
        "likes"=>"34",
        "location_path"=>"/threads/ah-fuck-it-im-hungry-worm-cyoa-si.7074/page-2#post-2121118",
        "position"=>"4",
        "title"=>"Static 4",
        "word_count"=>"2948"
      }.sort.to_h,
      chapter.attributes.except(*%w[ id story_id created_at updated_at likes_updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    assert_equal(7469, questionablequesting_story.word_count)
  end

  testing "sfw quests" do
    searcher = LocationSearcher::QuestionablequestingSearcher.new
    stories_html = File.read(File.expand_path("../pages/questionablequesting_sfw_quests.html", __FILE__))
    stories_html = SiteCrawler::HtmlParser.parse(stories_html)
    # parse stories
    results = searcher.update_stories_from_html!(stories_html, attributes: { category: "quest" }, chapters: false)
    assert_equal(true, results[:more])
    assert_equal([3, 3, 3], [results[:stories].size, QuestionablequestingStory.count, Story.count])
    # verify a story
    questionablequesting_story = QuestionablequestingStory.first
    assert_equal(
      {
        "author_name"=>"OneOfManyEyes",
        "average_chapter_likes"=>"0.0",
        "category"=>"quest",
        "clicks"=>"0", "highest_chapter_likes"=>"0",
        "is_nsfw"=>"false",
        "location_id"=>"thread-5473",
        "location_path"=>"/threads/flesh-and-steel-worm-tinker-quest.5473",
        "read_url"=>
         "https://forum.questionablequesting.com/threads/flesh-and-steel-worm-tinker-quest.5473",
        "story_created_on"=>"2017-04-09",
        "story_updated_at"=>"2017-04-09 00:00:00 -0700",
        "title"=>"Flesh and Steel [Worm Tinker Quest]",
        "word_count"=>"0"
      }.sort.to_h,
      questionablequesting_story.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    # parse story chapters
    chapters_html = File.read(File.expand_path("../pages/questionablequesting_sfw_quest_chapters.html", __FILE__))
    chapters_html = SiteCrawler::HtmlParser.parse(chapters_html)
    searcher.update_chapters_for_story_from_html!(questionablequesting_story, chapters_html)
    assert_equal(5, questionablequesting_story.chapters.count)
    chapter = questionablequesting_story.chapters.sort.first
    assert_equal(
      {
        "category"=>"chapter",
        "chapter_created_on"=>"2017-04-10",
        "chapter_updated_at"=>"2017-04-10 12:16:19 -0700",
        "likes"=>"9",
        "location_path"=>"/threads/flesh-and-steel-worm-tinker-quest.5473/",
        "position"=>"1",
        "title"=>"Who Are You?",
        "word_count"=>"250"
      }.sort.to_h,
      chapter.attributes.except(*%w[ id story_id created_at updated_at likes_updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    assert_equal(2912, questionablequesting_story.word_count)
  end

  testing "nsfw quests" do
    searcher = LocationSearcher::QuestionablequestingSearcher.new
    stories_html = File.read(File.expand_path("../pages/questionablequesting_nsfw_quests.html", __FILE__))
    stories_html = SiteCrawler::HtmlParser.parse(stories_html)
    # parse stories
    results = searcher.update_stories_from_html!(stories_html, attributes: { category: "quest", is_nsfw: true }, chapters: false)
    assert_equal(true, results[:more])
    assert_equal([1, 1, 1], [results[:stories].size, QuestionablequestingStory.count, Story.count])
    # verify a story
    questionablequesting_story = QuestionablequestingStory.first
    assert_equal(
      {
        "author_name"=>"koolerkid",
        "average_chapter_likes"=>"0.0",
        "category"=>"quest",
        "clicks"=>"0", "highest_chapter_likes"=>"0",
        "is_nsfw"=>"true",
        "location_id"=>"thread-7263",
        "location_path"=>"/threads/relationship-trouble-worm.7263",
        "read_url"=>
         "https://forum.questionablequesting.com/threads/relationship-trouble-worm.7263",
        "story_created_on"=>"2018-03-15",
        "story_updated_at"=>"2018-03-15 00:00:00 -0700",
        "title"=>"Relationship Trouble [Worm]",
        "word_count"=>"0"
      }.sort.to_h,
      questionablequesting_story.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    # parse story chapters
    chapters_html = File.read(File.expand_path("../pages/questionablequesting_nsfw_quest_chapters.html", __FILE__))
    chapters_html = SiteCrawler::HtmlParser.parse(chapters_html)
    searcher.update_chapters_for_story_from_html!(questionablequesting_story, chapters_html)
    assert_equal(4, questionablequesting_story.chapters.count)
    chapter = questionablequesting_story.chapters.sort.first
    assert_equal(
       {
        "category"=>"chapter",
        "chapter_created_on"=>"2018-03-15",
        "chapter_updated_at"=>"2018-03-15 22:52:03 -0700",
        "likes"=>"99",
        "location_path"=>"/threads/relationship-trouble-worm.7263/",
        "position"=>"1",
        "title"=>"Prologue",
        "word_count"=>"2631"
      }.sort.to_h,
      chapter.attributes.except(*%w[ id story_id created_at updated_at likes_updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    assert_equal(7219, questionablequesting_story.word_count)
  end

end
