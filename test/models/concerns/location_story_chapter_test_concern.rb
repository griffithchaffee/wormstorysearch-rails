module LocationStoryChapterConcern::TestConcern
  extend ActiveSupport::Concern

  included do
    testing "word_count" do
      chapter = FactoryBot.create(factory)
      {
        "123" => 123,
        "1.1k" => 1100, "1.25k" => 1250,
        "1.1m" => 1100000, "1.25m" => 1250000,
      }.each do |word_count_s, word_count|
        chapter.update!(word_count: word_count_s)
        assert_equal(word_count, chapter.word_count, "#{word_count_s}")
      end
    end

    testing "title strip" do
      chapter = FactoryBot.create(factory)
      chapter.update!(title: " \n\r TITLE \n\r ")
      assert_equal("TITLE", chapter.title)
    end

    testing "automatic created_on slight adjustment due to timezone" do
      chapter = FactoryBot.create(factory)
      chapter.story.update!(story_created_on: Date.today, story_updated_at: Date.today)
      chapter.update!(chapter_created_on: Date.yesterday, chapter_updated_at: Date.today)
      assert_equal(chapter.story.story_created_on, chapter.chapter_created_on)
    end
  end
end
