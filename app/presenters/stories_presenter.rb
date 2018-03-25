class StoriesPresenter < ApplicationPresenter
  presenter_options.presents = :story

  # label
  define_extension(:label, :title_label,       :title,  content: "Title")
  define_extension(:label, :author_label,      :author_id, content: "Author")
  define_extension(:label, :status_label,      :description, content: "Status")
  define_extension(:label, :crossover_label,   :crossover, content: "Crossover/Information")
  define_extension(:label, :description_label, :description, content: "Description")
  define_extension(:label_for, :merge_with_story_label, :merge_with_story_id, content: "Merge With:")
  # text_field
  define_extension(:text_field, :title_field,     :title, placeholder: "Messages from an Angel")
  define_extension(:text_field, :author_field,    :author, placeholder: "Ack")
  define_extension(:text_field, :crossover_field, :crossover, placeholder: "Justice League")
  # text_area
  define_extension(:text_area,  :description_field, :description, placeholder: "Short overview about this story", rows: 5)
  # select
  define_extension(:select, :status_select, :status, content: Story.const.statuses.nest(:label, :status))
  # check_box
  define_extension(:check_box, :is_nsfw_check_box, :is_nsfw)
  define_extension(:check_box, :is_archived_check_box, :is_archived)
  # span_tag
  define_extension(:span_tag, :is_nsfw_check_box_text, content: "NSFW?")
  define_extension(:span_tag, :is_archived_check_box_text, content: "Archive this story?")
  # link_to
  define_extension(:span_tag, :edit_link, content: "")
  # filters
  define_extension(:text_field_tag, :story_filter, :story_keywords, placeholder: "Title, Crossover, Author, or Description")
  define_extension(:text_field_tag, :rating_filter, :rating_filter, placeholder: "Rating")
  define_extension(:text_field_tag, :word_count_filter, :word_count_filter, placeholder: "Words")
  define_extension(:text_field_tag, :updated_after_filter, :updated_after_filter, placeholder: "MM/DD(/YY)")
  define_extension(:text_field_tag, :updated_before_filter, :updated_before_filter, placeholder: "MM/DD(/YY)")
  # sorters
  define_extension(:sorter_link, :story_created_on_sorter, "stories.story_created_on", content: "Created", default_direction: "desc")
  define_extension(:sorter_link, :title_sorter, "stories.title", content: "Title")
  define_extension(:sorter_link, :rating_sorter, "stories.rating", content: "Rating", default_direction: "desc")
  define_extension(:sorter_link, :word_count_sorter,"stories.word_count", content: "Words", default_direction: "desc")

  # custom fields
  def story_updated_at_sorter
    sorter_link("stories.story_updated_at", default_direction: "desc") do
      span_tag(add_class: "hidden-sm hidden-xs") { "Updated" } +
      span_tag(add_class: "hidden-md hidden-lg", title: "Updated", "aria-label" => "Updated") { icon("calendar") }
    end
  end

  def author_select(params = {})
    authors = StoryAuthor.pluck(:name, :id)
    select(:author_id, content: authors, prompt: "Author", add_class: "select2")
  end

  def merge_with_story_select(params = {})
    story = extract_record(params)
    stories = Story.preload(:author).select(:id, :title, :crossover, :author_id).seek(id_not_eq: story.id).map do |story|
      ["#{story.crossover_title.inspect} by #{story.author_name}", story.id]
    end
    select_tag(:merge_with_story_id, content: stories, prompt: "Find story...", add_class: "select2")
  end

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
    if view.is_admin?
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
    if view.is_admin?
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

  def row_alert_class(*hashes)
    story = extract_record(*hashes)
    story.recently_created? ? "info" : ""
  end

  def recently_created_icon(*hashes, &content_block)
    story = extract_record(*hashes)
    if story.recently_created?
      tooltip_content = "Created #{moment_span(story.story_created_on, :calendar_full)}".html_safe
      icon(
        "calendar-plus",
        title: "Created #{moment_span(story.story_created_on, :calendar_full)}",
        data: { toggle: "tooltip", placement: "top auto", trigger: "hover", content: tooltip_content, html: "true" }
      )
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
        content += li_tag(style: sub_li_style) { %Q[Default search is exact match ] }
        content += li_tag(style: sub_li_style) { %Q[Fuzzy Match: ~ ] + example_span.call("~fire pyro") }
        content += li_tag(style: sub_li_style) { %Q[Starts With: ^ ] + example_span.call("^ship") }
        content += li_tag(style: sub_li_style) { %Q[OR Match: | ] + example_span.call(%Q[fire|pyro]) }
        content += li_tag { b_tag(content: "Rating Filter") }
        content += li_tag(style: sub_li_style) { %Q[Normalized (hover for details)] }
        content += li_tag(style: sub_li_style) { %Q[Filter: >500 or <500 (default is >)] }
        content += li_tag { b_tag(content: "Words Filter") }
        content += li_tag(style: sub_li_style) { %Q[Filter: >10k or <10k (default is >)] }
      end
      icon(
        "info",
        title: popover_title,
        data: {
          toggle: "popover",
          placement: "top auto",
          trigger: "hover",
          content: popover_content,
          html: "true"
        }
      )
    end
  end

  def location_rating(location)
    location_rating = location.rating.to_i
    alternate_ratings =
      case location.const.location_slug.verify_in!(%w[ spacebattles sufficientvelocity fanfiction archiveofourown questionablequesting ])
      when "spacebattles"         then ["#{location.highest_chapter_likes.to_i} High", "#{location.average_chapter_likes.to_i} Avg"]
      when "sufficientvelocity"   then ["#{location.highest_chapter_likes.to_i} High", "#{location.average_chapter_likes.to_i} Avg"]
      when "fanfiction"           then ["#{location.favorites} Favs"]
      when "archiveofourown"      then ["#{location.kudos} Kudos"]
      when "questionablequesting" then ["#{location.highest_chapter_likes.to_i} High", "#{location.average_chapter_likes.to_i} Avg"]
      end
    alternate_ratings.map! do |alternate_rating|
      em_tag(content: "(#{alternate_rating})")
    end
    content = [location_rating, *alternate_ratings].join(" ").html_safe
    span_tag(content: content, style: "white-space: nowrap;")
  end

  def rating_details(*hashes)
    story = extract_record(*hashes)
    location_ratings = story.locations.map do |location|
      case location.const.location_slug.verify_in!(%w[ spacebattles sufficientvelocity fanfiction archiveofourown questionablequesting ])
      when "spacebattles"
        "#{location.const.location_abbreviation}: #{location.rating.to_i} (#{location.highest_chapter_likes.to_i} High) (#{location.average_chapter_likes.to_i} Avg)"
      when "sufficientvelocity"
        "#{location.const.location_abbreviation}: #{location.rating.to_i} (#{location.highest_chapter_likes.to_i} High) (#{location.average_chapter_likes.to_i} Avg)"
      when "fanfiction"
        "#{location.const.location_abbreviation}: #{location.rating.to_i} (#{location.favorites} Favs)"
      when "archiveofourown"
        "#{location.const.location_abbreviation}: #{location.rating.to_i} (#{location.kudos} Kudos)"
      when "questionablequesting"
        "#{location.const.location_abbreviation}: #{location.rating.to_i} (#{location.highest_chapter_likes.to_i} High) (#{location.average_chapter_likes.to_i} Avg)"
      end
    end
    location_ratings.unshift("Highly Rated!") if story.highly_rated?
    location_ratings_content = location_ratings.map { |content| span_tag(content: content.strip, style: "white-space: nowrap;") }.join(br_tag)
    send(story.highly_rated? ? :strong_tag : :span_tag,
      *hashes,
      content: story.rating.to_i,
      title: location_ratings_content,
      add_class: "tooltip-text-left",
      merge_data: { toggle: "tooltip", trigger: "hover", html: true }
    )
  end

end
