class Story::Test < ApplicationRecord::TestCase

  testing "location stories association inverse_of relationship" do
    story = FactoryBot.create(:story)
    Story.const.location_models.each do |location_model|
      location_story = FactoryBot.create(location_model.singular_slug, story: story)
      assert_equal(true, story.reload.send(location_model.plural_slug).load.first.story.equal?(story))
    end
  end

  testing "title description crossover normalization" do
    story = FactoryBot.create(:story)
    %w[ title description crossover ].each do |attribute|
      story.update!(attribute => " \n\r MULTI  WORD   VALUE \n\r ")
      assert_equal("MULTI WORD VALUE", story.send(attribute))
    end
  end

  testing "word_count" do
    story = FactoryBot.create(:story)
    {
      "123" => 123,
      "1.1k" => 1100, "1.25k" => 1250,
      "1.1m" => 1100000, "1.25m" => 1250000,
    }.each do |word_count_s, word_count|
      story.update!(word_count: word_count_s)
      assert_equal(word_count, story.word_count, "#{word_count_s}")
    end
  end

  testing "active_location" do
    story = FactoryBot.create(:story)
    spacebattles_story = FactoryBot.create(:spacebattles_story, story: story, story_updated_at: Date.today, story_created_on: Date.today - 3.days)
    sufficientvelocity_story = FactoryBot.create(:sufficientvelocity_story, story: story, story_updated_at: Date.today, story_created_on: Date.today - 3.days)
    fanfiction_story = FactoryBot.create(:fanfiction_story, story: story, story_updated_at: Date.today, story_created_on: Date.today - 3.days)
    # active_location prefence goes by story_updated_at then sorted location preference
    assert_equal(spacebattles_story, story.reload.active_location)
    spacebattles_story.update!(story_updated_at: Date.yesterday)
    assert_equal(sufficientvelocity_story, story.reload.active_location)
    sufficientvelocity_story.update!(story_updated_at: Date.yesterday)
    assert_equal(fanfiction_story, story.reload.active_location)
    fanfiction_story.update!(story_updated_at: Date.yesterday)
    assert_equal(spacebattles_story, story.reload.active_location)
    # additional stories
    new_spacebattles_story = FactoryBot.create(:spacebattles_story, story: story, story_updated_at: Date.today, story_created_on: Date.today - 3.days)
    new_sufficientvelocity_story = FactoryBot.create(:sufficientvelocity_story, story: story, story_updated_at: Date.today, story_created_on: Date.today - 3.days)
    new_fanfiction_story = FactoryBot.create(:fanfiction_story, story: story, story_updated_at: Date.today, story_created_on: Date.today - 3.days)
    assert_equal(new_spacebattles_story, story.reload.active_location)
    new_spacebattles_story.update!(story_updated_at: Date.yesterday)
    assert_equal(new_sufficientvelocity_story, story.reload.active_location)
    new_sufficientvelocity_story.update!(story_updated_at: Date.yesterday)
    assert_equal(new_fanfiction_story, story.reload.active_location)
    new_fanfiction_story.update!(story_updated_at: Date.yesterday)
    assert_equal(new_spacebattles_story, story.reload.active_location)
  end

  testing "sync_with_active_location!" do
    story = FactoryBot.create(:story)
    spacebattles_story = FactoryBot.create(:spacebattles_story, story: story, story_updated_at: Date.today - 3.days, story_created_on: Date.today - 3.days)
    sufficientvelocity_story = FactoryBot.create(:sufficientvelocity_story, story: story, story_updated_at: Date.today - 2.days, story_created_on: Date.today - 3.days)
    fanfiction_story = FactoryBot.create(:fanfiction_story, story: story, story_updated_at: Date.today - 1.day, story_created_on: Date.today - 3.days)
    max_word_count = [spacebattles_story, sufficientvelocity_story, fanfiction_story].map(&:word_count).max
    # syncs with active location
    assert_equal(fanfiction_story, story.reload.active_location)
    story.sync_with_active_location!
    assert_equal([max_word_count, fanfiction_story.story_updated_at], [story.reload.word_count, story.story_updated_at])
    # syncs after story_upated_at
    sufficientvelocity_story.reload.update!(story_updated_at: Date.today)
    assert_equal([max_word_count, sufficientvelocity_story.story_updated_at], [story.reload.word_count, story.story_updated_at])
    # syncs after word_count change if active
    fanfiction_story.reload.update!(word_count: 1_000_000_000)
    assert_equal([1_000_000_000, sufficientvelocity_story.story_updated_at], [story.reload.word_count, story.story_updated_at])
  end

  testing "achive_management!" do
    story = FactoryBot.create(:story)
    assert_equal(false, story.reload.is_archived?)
    spacebattles_story = FactoryBot.create(:spacebattles_story, story: story, story_updated_at: Date.today - 3.days, story_created_on: Date.today - 3.days)
    sufficientvelocity_story = FactoryBot.create(:sufficientvelocity_story, story: story, story_updated_at: Date.today - 2.days, story_created_on: Date.today - 3.days)
    fanfiction_story = FactoryBot.create(:fanfiction_story, story: story, story_updated_at: Date.today - 1.day, story_created_on: Date.today - 3.days)
    assert_equal(false, story.reload.is_archived?)
    # after destroy callback sets is_archived
    story.locations.each(&:destroy!)
    assert_equal(true, story.reload.is_archived?)
    # after save callback sets is_archived
    spacebattles_story = FactoryBot.create(:spacebattles_story, story: story, story_updated_at: Date.today - 3.days, story_created_on: Date.today - 3.days)
    assert_equal(false, story.reload.is_archived?)
    # manually call class helper
    story.update!(is_archived: true)
    assert_equal(true, story.reload.is_archived?)
    Story.reset_archived_state!
    assert_equal(false, story.reload.is_archived?)
    spacebattles_story.destroy!
    assert_equal(true, story.reload.is_archived?)
    story.update!(is_archived: false)
    assert_equal(false, story.reload.is_archived?)
    Story.reset_archived_state!
    assert_equal(true, story.reload.is_archived?)
  end

  testing "automatic story status update when story_updated_at changes" do
    story = FactoryBot.create(:story, story_created_on: 1.day.ago, story_updated_at: 1.hour.ago)
    story.reload.update!(status: "dead")
    assert_equal("dead", story.status)
    story.update!(story_updated_at: Time.now)
    assert_equal("ongoing", story.reload.status)
  end

  testing "update_hype_rating" do
    story = FactoryBot.create(:story, rating: 100, story_created_on: 36.hours.ago, hype_rating: 0)
    assert_same(0, story.reload.hype_rating)
    story.update_hype_rating!
    assert_same(2000, story.reload.hype_rating)
    story.update_rating!
    assert_same(0, story.reload.hype_rating)
  end

end
