class StoryChapter::Test < ApplicationRecord::TestCase

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

  testing "category autoset" do
    chapter = FactoryGirl.create(:story_chapter)
    assert_equal("chapter", chapter.category, category: nil)
    # omake a word in title
    ["omake", "ok omake title", "an omake", "omake chapter"].each do |title|
      chapter = FactoryGirl.create(:story_chapter, title: title, category: nil)
      assert_equal("omake", chapter.category, title)
    end
    ["not_omake", "NOTomakeTitle"].each do |title|
      chapter = FactoryGirl.create(:story_chapter, title: title, category: nil)
      assert_not_equal("omake", chapter.category, title)
    end
  end

end
