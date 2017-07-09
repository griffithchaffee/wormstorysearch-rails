class StoriesPresenter < ApplicationPresenter
  presenter_options.presents = :story

  # label
  define_extension(:label, :title_label,       :title,  content: "Title")
  define_extension(:label, :author_label,      :author, content: "Author")
  define_extension(:label, :status_label,      :description, content: "Status")
  define_extension(:label, :crossover_label,   :crossover, content: "Crossover")
  define_extension(:label, :description_label, :description, content: "Description")
  # text_field
  define_extension(:text_field, :title_field,     :title, placeholder: "Messages from an Angel")
  define_extension(:text_field, :author_field,    :author, placeholder: "Ack")
  define_extension(:text_field, :crossover_field, :crossover, placeholder: "Justice League")
  # text_area
  define_extension(:text_area,  :description_field, :description, placeholder: "Short overview about this story", rows: 5)
  # select
  define_extension(:select, :status_select, :status, content: Story.const.statuses.nest(:label, :status))
  # check_box
  define_extension(:check_box, :is_locked_check_box,   :is_locked)
  define_extension(:check_box, :is_archived_check_box, :is_archived)
  # span_tag
  define_extension(:span_tag, :is_locked_check_box_text,   content: "Lock this story to prevent any future updates")
  define_extension(:span_tag, :is_archived_check_box_text, content: "Archive this story to hide from index")
  # link_to
  define_extension(:span_tag, :edit_link, content: "")
  # filters
  define_extension(:text_field_tag, :story_filter,      :story_keywords, placeholder: "Title, Crossover, Author, or Description")
  define_extension(:text_field_tag, :word_count_filter, :word_count_gteq, placeholder: "Words")
  # sorters
  define_extension(:sorter_link, :story_created_on_sorter, "stories.story_created_on", content: "Created", default_direction: "desc")
  define_extension(:sorter_link, :story_updated_at_sorter, "stories.story_updated_at", content: "Updated", default_direction: "desc")
  define_extension(:sorter_link, :title_sorter,            "stories.title", content: "Title")
  define_extension(:sorter_link, :word_count_sorter,       "stories.word_count", content: "Words", default_direction: "desc")

  # html
  def index_link(*hashes, &content_block)
    default_content = icon_content(*hashes, icon: "list", content: "Stories")
    link_to(view.stories_path, *hashes, content: default_content, &content_block)
  end
  define_extension(:index_link, :index_link_btn, add_class: "btn btn-default")

  def show_link(*hashes, &content_block)
    story = extract_record(*hashes)
    default_content = icon_content(*hashes, icon: "list", content: "Show")
    link_to(view.story_path(story), *hashes, content: default_content, &content_block)
  end
  define_extension(:show_link, :show_link_btn, add_class: "btn btn-default")

  def edit_link(*hashes, &content_block)
    story = extract_record(*hashes)
    default_content = icon_content(*hashes, icon: "edit", content: "Edit")
    if story.is_unlocked? || view.is_admin?
      link_to(view.edit_story_path(story), *hashes, content: default_content, &content_block)
    end
  end
  define_extension(:edit_link, :edit_link_btn, add_class: "btn btn-default")

  def read_link(*hashes, &content_block)
    record = extract_record(*hashes)
    default_content = icon_content(*hashes, icon: "external-link", content: "Read")
    tab_link(record.read_url, *hashes, content: default_content, &content_block)
  end
  define_extension(:read_link, :read_link_btn, add_class: "btn btn-primary")

  def modal_show_link(*hashes, &content_block)
    story = extract_record(*hashes)
    default_content = icon_content(*hashes, icon: "list", content: "Show")
    dynamic_modal_link(
      view.story_path(story),
      *hashes,
      title: "View details",
      merge_data: { toggle: "desktop-tooltip" },
      content: default_content,
      &content_block
    )
  end
  define_extension(:modal_show_link, :modal_show_link_btn, add_class: "btn btn-default")

  def modal_edit_link(*hashes, &content_block)
    story = extract_record(*hashes)
    default_content = icon_content(*hashes, icon: "edit", content: "Edit")
    if story.is_unlocked? || view.is_admin?
      dynamic_modal_link(
        view.edit_story_path(story),
        *hashes,
        title: "Edit details",
        merge_data: { toggle: "desktop-tooltip" },
        content: default_content,
        &content_block
      )
    end
  end
  define_extension(:modal_edit_link, :modal_edit_link_btn, add_class: "btn btn-default")

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

  def filters_info_icon
    div_tag(add_class: "text-center search-hide filters-info") do
      popover_title = b_tag(content: "Advanced Filtering")
      popover_content = ul_tag do
        content = "".html_safe
        sub_li_style = "margin-left: 10px;"
        example_span = -> (content) { span_tag(style: "", content: "(Ex: #{content})") }
        content += li_tag { b_tag(content: "Keywords Filter") }
        content += li_tag(style: sub_li_style) { %Q[Starts With: ^ ] + example_span.call("^ship") }
        content += li_tag(style: sub_li_style) { %Q[Exact Match: "Quotes" ] + example_span.call(%Q["To Reign"]) }
        content += li_tag { b_tag(content: "Words Filter") }
        content += li_tag(style: sub_li_style) { %Q[Shorthand: 10k ] }
      end
      icon("info", title: popover_title, class: "icon-md", data: { toggle: "popover", placement: "top auto", trigger: "hover", content: popover_content, html: "true" })
    end
  end

end
