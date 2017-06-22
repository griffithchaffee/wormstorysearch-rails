class StoriesPresenter < ApplicationPresenter

  # filters
  def story_updated_at_filter
    content = {
      "3 Hours"  => 3.hours.ago.beginning_of_hour,
      "6 Hours"  => 6.hours.ago.beginning_of_hour,
      "12 Hours" => 12.hours.ago.beginning_of_hour,
      "1 Day"    => 1.day.ago.to_date,
      "3 Days"   => 3.days.ago.to_date,
      "1 Week"   => 1.week.ago.to_date,
    }
    select_tag(:story_updated_at_gteq, content: content, prompt: "Within...")
  end

  def title_filter(params = {})
    text_field_tag(:title_matches, params, placeholder: "By title...")
  end

  # sorters
  def word_count_sorter
    sorter_link("stories.word_count", content: "Words")
  end

  def story_updated_at_sorter
    sorter_link("stories.story_updated_at", content: "Updated")
  end

  def title_sorter
    sorter_link("stories.title", content: "Title")
  end

end
