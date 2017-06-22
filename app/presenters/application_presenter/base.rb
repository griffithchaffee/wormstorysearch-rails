class ApplicationPresenter < ActionPresenter::Base

  def namespace_dasherized(namespaces)
    Array(namespaces).flatten.join("-").gsub(/[^A-Za-z0-9-]/, "-").remove(/\A-+|-+\z/).squeeze("-")
  end

  def record_to_namespace(record)
    "#{record.class.model_name.singular}_#{record.id}"
  end

  def current_path(override_params = {})
    view.request.path_parameters.deep_merge(override_params.to_h)
  end

  def current_query_path(override_params = {})
    view.request.query_parameters.deep_merge(override_params.to_h)
  end

  def sorter_link(new_sort, *hashes, &content_block)
    new_direction = extract(:default_direction, *hashes, default_direction: "asc")
    active_sort, active_direction, new_sort = view.params[:sort].to_s, view.params[:direction].to_s, new_sort.to_s
    add_classes = ["sorter"]
    # switching direction on active_sort
    if active_sort == new_sort
      add_classes << "active"
      new_direction = active_direction =~ /desc/i ? "asc" : "desc"
    end
    # build sorter
    sorter_link_path = current_query_path(sort: new_sort, direction: new_direction)
    link_to(sorter_link_path, *hashes, add_class: add_classes.join(" ")) do
      content = "".html_safe
      content << extract_content(*hashes, &content_block)
      # switching direction on active_sort
      if active_sort == new_sort
        # ascend means to move "up" so chevron-up
        content + " " + icon(active_direction =~ /desc/i ? "chevron-down" : "chevron-up")
      else
        content
      end
    end
  end

  def reset_filter
    div_tag(add_class: "text-center") do
      void_link(add_class: "search-reset", style: "display: none;") do
        icon("ban", title: "Reset Filters", style: "font-size: 16px; padding-top: 6px;")
      end
    end
  end

end
