class StoryAuthorsPresenter < ApplicationPresenter
  presenter_options.presents = :story_author

  # label
  define_extension(:label, :name_label, :name, content: "Name:")
  Story.const.location_models.each do |location_model|
    define_extension(
      :label,
      "#{location_model.const.location_slug}_name_label",
      "#{location_model.const.location_slug}_name",
      content: "#{location_model.const.location_label} Name:"
    )
  end
  # text_field
  define_extension(:text_field, :name_field, :name, placeholder: "John Smith")
  Story.const.location_models.each do |location_model|
    define_extension(
      :text_field,
      "#{location_model.const.location_slug}_name_field",
      "#{location_model.const.location_slug}_name",
      placeholder: "John Smith"
    )
  end
  # filters
  define_extension(:text_field_tag, :name_filter, :any_name_matches, placeholder: "Ack")
  # sorters
  define_extension(:sorter_link, :name_sorter, "story_authors.name", content: "Author Name")

  # html
  def index_link(*hashes, &content_block)
    default_content = icon_content(*hashes, icon: "list", content: "Authors")
    link_to(view.story_authors_path, *hashes, content: default_content, &content_block)
  end

  def modal_edit_link(*hashes, &content_block)
    story_author = extract_record(*hashes)
    default_content = icon_content(*hashes, icon: "edit", content: "Edit")
    if view.is_admin?
      dynamic_modal_link(
        view.edit_story_author_path(story_author),
        *hashes,
        title: "Edit details",
        merge_data: { toggle: "desktop-tooltip" },
        content: default_content,
        &content_block
      )
    end
  end

  def destroy_link(*hashes, &content_block)
    story_author = extract_record(*hashes)
    default_content = icon_content(*hashes, icon: "trash", content: "Delete")
    if view.is_admin?
      link_to(
        view.story_author_path(story_author),
        *hashes,
        method: :delete,
        data: { confirm: "Are you sure you want to delete the author: #{story_author.name.inspect}" },
        content: default_content,
        &content_block
      )
    end
  end

end
