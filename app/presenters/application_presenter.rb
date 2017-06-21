class ApplicationPresenter < ActionPresenter::Base

  generate_bootstrap_presenter_methods!

  define_html_method_extension(:div_tag, :container_div, class: "container")
  define_html_method_extension(:div_tag, :btn_group_div, class: "btn-group")

  def icon(icon, *hashes, &content_block)
    # optional tooltip
    tooltip_direction = extract(:tooltip, *hashes).to_s.presence
    if tooltip_direction
      tooltip_direction = "top" if tooltip_direction == true
      hashes << { data: { toggle: "tooltip", placement: tooltip_direction } }
    end
    # optional popover
    popover_direction = extract(:popover, *hashes).to_s.presence
    if popover_direction
      popover_direction = "top" if popover_direction == true
      hashes << { data: { toggle: "popover", placement: popover_direction, content: extract(:title, *hashes), trigger: "hover" } }
    end
    span_tag(*hashes, add_class: "icon icon-#{icon}", &content_block)
  end

  def page_title(*hashes, &content_block)
    title_content = extract_content(*hashes, &content_block)
    sub_title_content = extract(:sub_title, *hashes)
    sub_text_content = extract(:sub_text, *hashes)
    insert_divider = extract(:divider, *hashes)
    page_title = h1_tag(*hashes, add_class: "page-title", data: { blah: "blah" }) do
      content = "".html_safe + title_content
      content += small_tag(content: sub_title_content) if sub_title_content.present?
      content
    end
    page_title += sub_title(content: sub_text_content) if sub_text_content.present?
    page_title += legend_tag if insert_divider == true
    page_title
  end
  define_html_method_extension(:h3_tag, :section_title, add_class: "section-title")
  define_html_method_extension(:h6_tag, :sub_title, add_class: "sub-title")

  # links
  def home_link(*hashes, &content_block)
    link_to(view.root_path, *hashes, content: "Home", &content_block)
  end
  define_html_method_extension(:home_link, :home_link_btn, add_class: "btn btn-default")

  def back_link(*hashes, &content_block)
    link_to("javascript:history.back()", *hashes, content: "Back", &content_block)
  end
  define_html_method_extension(:back_link, :back_link_btn, add_class: "btn btn-default")

end
