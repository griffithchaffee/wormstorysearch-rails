class ApplicationPresenter < ActionPresenter::Base

  # col
  define_extension(:col_div,          :full_div,            col_sm: 12, col_md: 12)
  #define_extension(:col_class,        :label_for_class,     col_sm: 3, col_md: 2, add_class: :core_label_class)
  #define_extension(:col_offset_class, :label_for_gap_class, col_sm: 3, col_md: 2)
  # div
  define_extension(:div_tag, :container_div,    class: "container")
  define_extension(:div_tag, :btn_group_div,    class: "btn-group")
  define_extension(:div_tag, :page_header_div,  class: "page-header-container")
  define_extension(:div_tag, :page_actions_div, class: "page-actions pull-right btn-group")
  # other
  define_extension(:h3_tag,     :section_header,  add_class: "section-header")
  define_extension(:span_tag,   :help_span,       add_class: "help-block")
  define_extension(:submit_tag, :form_submit_btn, add_class: "btn btn-primary")
  define_extension(:submit_tag, :submit_btn,      add_class: "btn btn-primary")

  def form_submit_div(*hashes)
    div_tag(add_class: "form-submit") do
      content = form_submit_btn(add_class: "submit")
      content += back_link_btn(add_class: "secondary-link")
    end
  end

  def icon(icon, *hashes, &content_block)
    span_tag(*hashes, add_class: "icon icon-#{icon}", "aria-label" => "#{icon.to_s.titleize} Icon", &content_block)
  end

  def page_title(*hashes, &content_block)
    title_content = extract_content(*hashes, &content_block)
    sub_text_content = extract(:sub_text, *hashes)
    sub_header_content = extract(:sub_header, *hashes)
    insert_divider = extract(:divider, *hashes)
    # build header
    h1_tag(*hashes, add_class: "page-title") do
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

  def modal_submit_btn(*hashes, &content_block)
    id = extract(:id, *hashes)
    submit_form_js = id ? "$('##{id}').submit();" : "$(this).parents('.modal').find('form').submit();"
    submit_btn(*hashes, onclick: submit_form_js, merge_data: { dismiss: "modal" }, &content_block)
  end

  def dynamic_modal_link(path, *hashes, &content_block)
    title = extract(:title, *hashes)
    link_to(path, *hashes, title: title, "aria-label" => "#{title} modal toggle", add_class: "dynamic-modal", &content_block)
  end

  def icon_content(*hashes, &content_block)
    content_icon  = extract(:icon, *hashes)
    content_class = extract(:content_class, *hashes)
    content_span  = span_tag(class: content_class, content: extract_content(*hashes))
    content = icon(content_icon) + " " + content_span
  end

  def moment_span(time, format, *hashes, &content_block)
    key = time.is_time? ? "time" : "date"
    span_tag(
      *hashes,
      merge_data: { moment: { type: key, unix: time.to_i, format: format.to_s } },
      content: time.send("to_#{format}_s")
    )
  end

  alias_method(:original_dropdown_toggle_btn, :dropdown_toggle_btn)
  def dropdown_toggle_btn(*hashes, &content_block)
    original_dropdown_toggle_btn(*hashes, "aria-haspopup" => "true", "aria-expanded" => "false", &content_block)
  end

end
