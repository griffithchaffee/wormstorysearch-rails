class ApplicationPresenter < ActionPresenter::Base

  # col
  define_extension(:col_div, :full_div, col_sm: 8, col_md: 6)
  define_extension(:col_class,        :label_for_class,     col_sm: 3, col_md: 2, add_class: :core_label_class)
  define_extension(:col_offset_class, :label_for_gap_class, col_sm: 3, col_md: 2)
  # col modal
  define_extension(:col_div,          :modal_full_div,        col_xs: 9)
  define_extension(:col_class,        :modal_label_class,     col_xs: 3)
  define_extension(:col_offset_class, :modal_label_gap_class, col_xs: 3)
  # div
  define_extension(:div_tag, :container_div, class: "container")
  define_extension(:div_tag, :btn_group_div, class: "btn-group")
  # other
  define_extension(:h3_tag,     :section_header,  add_class: "section-header")
  define_extension(:submit_tag, :form_submit_btn, add_class: "btn btn-primary")
  define_extension(:span_tag,   :help_span,       add_class: "help-block")

  def form_submit_div(*hashes)
    full_div(add_class: "#{label_for_gap_class} form-submit") do
      content = form_submit_btn(add_class: "submit")
      content += back_link_btn(add_class: "secondary-link")
    end
  end

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

  def page_header(*hashes, &content_block)
    title_content = extract_content(*hashes, &content_block)
    sub_text_content = extract(:sub_text, *hashes)
    sub_header_content = extract(:sub_header, *hashes)
    insert_divider = extract(:divider, *hashes)
    # build header
    h1_tag(*hashes, add_class: "page-header") do
      content = "".html_safe + title_content
      content += " ".html_safe + small_tag(content: sub_text_content) if sub_text_content.present?
      content += " ".html_safe + strong_tag(content: sub_header_content) if sub_header_content.present?
      content
    end
  end

  # links/btns
  def home_link(*hashes, &content_block)
    link_to(view.root_path, *hashes, content: "Home", &content_block)
  end
  define_extension(:home_link, :home_link_btn, add_class: "btn btn-default")

  def back_link(*hashes, &content_block)
    link_to("javascript:history.back()", *hashes, content: "Back", &content_block)
  end
  define_extension(:back_link, :back_link_btn, add_class: "btn btn-default")

  def void_link(*hashes, &content_block)
    link_to("javascript:void(0)", *hashes, &content_block)
  end
  define_extension(:void_link, :void_link_btn, add_class: "btn btn-default")

  def dismiss_action(action, *hashes, &content_block)
    default_content = span_tag("aria-hidden" => "true", content: "&times;".html_safe)
    dismiss_button(action, *hashes, class: "close", content: default_content, &content_block)
  end

  def modal_close_btn(*hashes, &content_block)
    dismiss_button(:modal, *hashes, add_class: "btn btn-default", content: "Close")
  end

  define_extension(:submit_tag, :submit_btn, add_class: "btn btn-primary")

  def modal_submit_btn(*hashes, &content_block)
    id = extract(:id, *hashes)
    submit_form_js = id ? "$('##{id}').submit();" : "$(this).parents('.modal').find('form').submit();"
    submit_btn(*hashes, onclick: submit_form_js, merge_data: { dismiss: "modal" }, &content_block)
  end

  # html
  def modal_link(path, *hashes, &content_block)
    link_to(path, *hashes, add_class: "dynamic-modal", &content_block)
  end

  def modal_show_link(*hashes, &content_block)
    record = extract_record(*hashes)
    content_icon = extract(:icon, *hashes, icon: "eye")
    content_span = span_tag(class: "hidden-sm hidden-xs", content: extract_content(*hashes, content: "Show"))
    content = icon(content_icon) + " " + content_span
    modal_link(view.polymorphic_path(record, layout: "modal"), *hashes, content: content, &content_block)
  end
  define_extension(:modal_show_link, :modal_show_link_btn, add_class: "btn btn-default")

  def modal_edit_link(*hashes, &content_block)
    record = extract_record(*hashes)
    content_icon = extract(:icon, *hashes, icon: "edit")
    content_span = span_tag(class: "hidden-sm hidden-xs", content: extract_content(*hashes, content: "Edit"))
    content = icon(content_icon) + " " + content_span
    modal_link(view.polymorphic_path(record, action: "edit", layout: "modal"), *hashes, content: content, &content_block)
  end
  define_extension(:modal_edit_link, :modal_edit_link_btn, add_class: "btn btn-default")

end
