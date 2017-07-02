class Story::Test < ApplicationRecord::TestCase

  testing "title description crossover normalization" do
    story = FactoryGirl.create(:story)
    %w[ title description crossover ].each do |attribute|
      story.update!(attribute => " \n\r MULTI  WORD   VALUE \n\r ")
      assert_equal("MULTI WORD VALUE", story.send(attribute))
    end
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

end
