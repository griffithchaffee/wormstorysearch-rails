class StoriesPresenter < ApplicationPresenter
  presenter_options.presents = :story

  # form
  def crossover_label(*hashes)
    label(:crossover, *hashes, content: "Crossover:")
  end

  def crossover_field(*hashes)
    text_field(:crossover, *hashes, placeholder: "Justice League")
  end

  def description_label(*hashes)
    label(:description, *hashes, content: "Description:")
  end

  def description_field(*hashes)
    text_area(:description, *hashes, placeholder: "Short overview about story", rows: 3)
  end

  def is_locked_label(*hashes)
    label(:is_locked, *hashes, content: "Lock:")
  end

  def is_locked_check_box(*hashes)
    check_box(:is_locked, *hashes)
  end

  def is_locked_check_box_text
    "Lock this story to prevent any future updates"
  end

  # html
  def status_class
    record.recently_created? ? "info" : ""
  end

  def recently_created_icon(*hashes, &content_block)
    if record.recently_created?
      icon("calendar", tooltip: "top", title: "Created #{record.story_created_on.friendly_b_d.capitalize}")
    end
  end

  # filters
  def details_filter(params = {})
    "Details"
  end

  def story_updated_at_filter
    content = {
      "3 Hours"  => 3.hours.ago.beginning_of_hour,
      "6 Hours"  => 6.hours.ago.beginning_of_hour,
      "12 Hours" => 12.hours.ago.beginning_of_hour,
      "1 Day"    => 1.day.ago.to_date,
      "3 Days"   => 3.days.ago.to_date,
      "1 Week"   => 1.week.ago.to_date,
    }
    select_tag(:story_updated_at_gteq, content: content, prompt: "Updated...")
  end

  def title_filter(params = {})
    text_field_tag(:title_matches, params, placeholder: "By title...")
  end

  def word_count_filter(params = {})
    text_field_tag(:word_count_gteq, params, placeholder: "Words...")
  end

  def author_filter(params = {})
    text_field_tag(:author_matches, params, placeholder: "Author...")
  end

  # sorters
  def story_created_on_sorter
    sorter_link("stories.story_created_on", content: "Created", default_direction: "desc")
  end

  def story_updated_at_sorter
    sorter_link("stories.story_updated_at", content: "Updated", default_direction: "desc")
  end

  def title_sorter
    sorter_link("stories.title", content: "Title")
  end

  def author_sorter
    sorter_link("stories.author", content: "Author")
  end

  def word_count_sorter
    sorter_link("stories.word_count", content: "Words", default_direction: "desc")
  end

end
