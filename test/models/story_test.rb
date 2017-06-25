class Story::Test < ApplicationRecord::TestCase

  testing "location" do
    Story.const.locations.each do |const|
      story = FactoryGirl.create(:story, location: const.location)
      story.update!(location: const.location)
      assert_equal(story.const.locations.fetch(const.location).label, story.location_label)
      assert_equal(story.const.locations.fetch(const.location).host, story.location_host)
      assert_equal("#{story.location_host}#{story.location_path}", story.location_url)
      # no chapters
      assert_equal(story.location_url, story.read_url)
      FactoryGirl.create(:story_chapter, story: story)
      assert_equal("#{story.location_url}/threadmarks", story.reload.read_url)
    end
    story = FactoryGirl.create(:story)
    assert_equal(false, story.update(location: "unknown"))
  end

  testing "word_count" do
    story = FactoryGirl.create(:story)
    {
      "123" => 123,
      "1.1k" => 1100, "1.25k" => 1250,
      "1.1m" => 1100000, "1.25m" => 1250000,
    }.each do |word_count_s, word_count|
      story.update!(word_count: word_count_s)
      assert_equal(word_count, story.word_count, "#{word_count_s}")
    end
  end

  testing "title strip" do
    story = FactoryGirl.create(:story)
    story.update!(title: " \n\r TITLE \n\r ")
    assert_equal("TITLE", story.title)
  end

  testing "story_updated_at autoset" do
    story = FactoryGirl.create(:story)
    chapter = FactoryGirl.create(:story_chapter, story: story, chapter_updated_at: 1.hour.ago)
    # story should be updated when chapter created
    assert_equal(chapter.chapter_updated_at.strftime("%T"), story.reload.story_updated_at.strftime("%T"))
    # story should be updated when saved
    story.update!(story_updated_at: 1.day.ago)
    assert_equal(chapter.chapter_updated_at.strftime("%T"), story.reload.story_updated_at.strftime("%T"))
  end

end
