module LocationStoryConcern::TestConcern
  extend ActiveSupport::Concern

  included do
    testing "word_count" do
      story = FactoryGirl.create(factory)
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
      story = FactoryGirl.create(factory)
      story.update!(title: " \n\r TITLE \n\r ")
      assert_equal("TITLE", story.title)
    end

    testing "story_updated_at autoset" do
      story = FactoryGirl.create(factory)
      chapter = FactoryGirl.create("#{factory}_chapter", story: story, chapter_updated_at: 1.hour.ago)
      # story should be updated when chapter created
      assert_equal(chapter.chapter_updated_at.to_i, story.reload.story_updated_at.to_i)
      # story should be updated when saved
      story.update!(story_updated_at: 1.day.ago)
      assert_equal(chapter.chapter_updated_at.to_i, story.story_updated_at!.to_i)
      assert_equal(1.day.ago.to_i, story.story_updated_at.to_i)
    end
  end
end
