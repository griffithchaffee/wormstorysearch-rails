module LocationStoryChapterConcern::TestConcern
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
  end
end
