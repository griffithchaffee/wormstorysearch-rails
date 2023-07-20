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
    content = "".html_safe
    content << extract_content(*hashes, &content_block)
    link_to(sorter_link_path, *hashes, add_class: add_classes.join(" ")) do
      # switching direction on active_sort
      if active_sort == new_sort
        # ascend means to move "up" so chevron-up
        content + " " +
        if active_direction =~ /desc/i
          icon("chevron-down", add_class: "hidden-sm hidden-xs", "aria-label" => "Sorted Descending") +
          icon("chevron-down", add_class: "hidden-md hidden-lg icon-sm", "aria-label" => "Sorted Descending")
        else
          icon("chevron-up", add_class: "hidden-sm hidden-xs", "aria-label" => "Sorted Ascending") +
          icon("chevron-up", add_class: "hidden-md hidden-lg icon-sm", "aria-label" => "Sorted Ascending")
        end
      else
        content
      end
    end
  end

  def filters_reset_icon(params = {})
    icon("ban", params, add_class: "search-reset text-danger", style: "cursor: pointer;")
  end

  def filters_reset_div_icon(params = {})
    div_tag(add_class: "text-center search-reset text-danger", style: "cursor: pointer;") do
      icon("ban", params)
    end
  end

  def actions_sorter
    "Actions"
  end

  def coffee_script_compile(coffee_script)
    CoffeeScript.compile(coffee_script.unindent)
  end

  def event_coffee_script_compile(coffee_script)
    coffee_script_compile("$this = $(this)\n$event = $.Event(event)\n#{coffee_script.unindent}\nreturn true")
  end

  def event_js(js_script)
    %Q{
      (function() {
        var $event, $this;
        $this = $(this);
        $event = $.Event(event);
        #{js_script.indent(2)}
        return true;
      }).call(this);
    }.unindent
  end

end
