class StoriesPresenter < ApplicationPresenter
  presenter_options.presents = :story

  # form
  define_extension(:label, :title_label,       :title,  content: "Title:")
  define_extension(:label, :author_label,      :author, content: "Author:")
  define_extension(:label, :crossover_label,   :crossover, content: "Crossover:")
  define_extension(:label, :description_label, :description, content: "Description:")

  define_extension(:text_field, :title_field,     :title, placeholder: "Messages from an Angel")
  define_extension(:text_field, :author_field,    :author, placeholder: "Ack")
  define_extension(:text_field, :crossover_field, :crossover, placeholder: "Justice League")

  define_extension(:text_area,  :description_field, :description, placeholder: "Short overview about this story", rows: 5)

  define_extension(:check_box, :is_locked_check_box,   :is_locked)
  define_extension(:check_box, :is_archived_check_box, :is_archived)

  define_extension(:span_tag, :is_locked_check_box_text, content: "Lock this story to prevent any future updates")
  define_extension(:span_tag, :is_archived_check_box_text, content: "Archive this story to hide from index")

  # html
  def status_class(*hashes)
    story = extract_record(*hashes)
    story.recently_created? ? "info" : ""
  end

  def recently_created_icon(*hashes, &content_block)
    story = extract_record(*hashes)
    if story.recently_created?
      icon("calendar", tooltip: "top", title: "Created #{story.story_created_on.to_full_human_s}")
    end
  end

  def read_story_link(*hashes, &content_block)
    record = extract_record(*hashes)
    default_content = icon("external-link") + " " + extract_content(*hashes, content: "Read")
    tab_link(record.read_url, *hashes, content: default_content, &content_block)
  end
  define_extension(:read_story_link, :read_story_link_btn, add_class: "btn btn-primary")

  # filters
  def story_filter(params = {})
    text_field_tag(:story_matches, params, placeholder: "Title, Crossover, or Author")
  end

  def word_count_filter(params = {})
    text_field_tag(:word_count_gteq, params, placeholder: "Words")
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

  def word_count_sorter
    sorter_link("stories.word_count", content: "Words", default_direction: "desc")
  end

end
