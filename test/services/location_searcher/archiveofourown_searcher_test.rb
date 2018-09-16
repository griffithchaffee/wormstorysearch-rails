class LocationSearcher::ArchiveofourownSearcher::Test < ApplicationTestCase

  testing "stories" do
    searcher = LocationSearcher::ArchiveofourownSearcher.new
    stories_html = File.read(File.expand_path("../pages/archiveofourown_stories.html", __FILE__))
    stories_html = SiteCrawler::HtmlParser.parse(stories_html)
    # parse stories
    results = searcher.update_stories_from_html!(stories_html, chapters: false)
    assert_equal(true, results[:more])
    assert_equal([20, 20, 19], [results[:stories].size, ArchiveofourownStory.count, Story.count])
    # verify a story
    archiveofourown_story = ArchiveofourownStory.first
    assert_equal(
      {
        "author_name"=>"Lithos_Maitreya",
        "category"=>"story",
        "clicks"=>"0",
        "crossover"=>"The Lord of the Rings - J. R. R. Tolkien",
        "description"=>"Taylor Hebert had a bad day, and came out of it changed.Some parahumans can control bugs. Some can build advanced technology. Some can do unspeakable things to space and time.Taylor can make magic rings, wondrous metals, mysterious weapons, and may not be a parahuman--or, indeed, human--at all.",
        "is_nsfw"=>"false",
        "kudos"=>"368",
        "kudos_updated_at"=>archiveofourown_story.attributes["kudos_updated_at"].to_s.presence,
        "location_id"=>"11392257",
        "location_path"=>"/works/11392257",
        "read_url"=>"https://archiveofourown.org/works/11392257",
        "status"=>"ongoing",
        "story_created_on"=>"2018-01-31",
        "story_updated_at"=>"2018-01-31 00:00:00 -0800",
        "title"=>"Ring-Maker",
        "word_count"=>"188295"
      }.sort.to_h,
      archiveofourown_story.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
    # parse story chapters
    chapters_html = File.read(File.expand_path("../pages/archiveofourown_story_chapters.html", __FILE__))
    chapters_html = SiteCrawler::HtmlParser.parse(chapters_html)
    searcher.update_chapters_for_story_from_html!(archiveofourown_story, chapters_html)
    assert_equal(76, archiveofourown_story.chapters.count)
    chapter = archiveofourown_story.chapters.first
    assert_equal(
      {
        "category"=>"chapter",
        "chapter_created_on"=>"2017-07-03",
        "chapter_updated_at"=>"2017-07-03 00:00:00 -0700",
        "location_path"=>"/works/11392257/chapters/25512489",
        "position"=>"1",
        "title"=>"Glimmer 1.1",
        "word_count"=>"0"
      },
      chapter.attributes.except(*%w[ id story_id created_at updated_at ]).map { |k,v| [k, v.to_s] }.to_h.sort.to_h
    )
  end
end
