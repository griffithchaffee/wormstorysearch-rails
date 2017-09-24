class TimeZoneIntegrationTest < ApplicationIntegrationTestCase

  testing "stories updated at uses time zone" do
    # setup
    story = FactoryGirl.create(:story)
    rails_time = story.story_updated_at

    # get with default timezone
    get "/stories"
    assert_response_ok
    assert_in_response_body([
      story.crossover_title,
      rails_time.to_full_human_s
    ])
    assert_mail_queue(0)

    # setup browser time
    time_zone_offset = -2
    cookies["browser.identity"] = { "time_zone_offset" => time_zone_offset }.to_json
    get "/stories"
    assert_response_ok
    assert_in_response_body([
      story.crossover_title,
      rails_time.in_time_zone("Etc/GMT+#{time_zone_offset.abs}").to_full_human_s
    ])
    # original time zone not included
    assert_not_in_response_body(rails_time.to_full_human_s)
    assert_mail_queue(0)

    # invalid time_zone_offset
    time_zone_offset = -50
    cookies["browser.identity"] = { "time_zone_offset" => time_zone_offset }.to_json
    get "/stories"
    assert_response_ok
    assert_in_response_body([
      story.crossover_title,
      rails_time.to_full_human_s
    ])
    assert_mail(0, subject: "ApplicationTimeZone ArgumentError: Invalid Timezone: Etc/GMT+50")
  end

end
