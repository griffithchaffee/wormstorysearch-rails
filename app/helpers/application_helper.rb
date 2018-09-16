module ApplicationHelper

  def render_optional_partial(partials, locals = {}, &block)
    render_partial(partials, locals, optional_partial: true, &block)
  end

  def render_partial(partials, locals = {}, options = {}, &block)
    locals = locals.symbolize_keys
    options = options.with_indifferent_access
    # passed arguments
    locals[:block] = block if block
    # dup to prevent infinite self-referencing
    locals[:locals] = locals.dup
    # directories
    root_dir = "#{Rails.root}/app/views"
    caller_file = caller[0].split(":").first
    caller_dir = File.dirname(caller_file)
    controller_dir = "#{root_dir}/#{controller_name}"
    controller_partials_dir = "#{controller_dir}/partials"
    global_partials_dir = "#{root_dir}/partials"
    # standardize partials
    partials = Array(partials).map(&:to_s)
    partials.map! do |partial|
      partial_file = File.basename(partial)
      partial_dir = File.dirname(partial)
      partial_file.prepend("_") if !partial_file.starts_with?("_")
      # default .html.erb extension
      partial_file.concat(".html.erb") if !partial_file.include?(".")
      partial = partial_dir == "." ? partial_file : partial_dir + "/" + partial_file
    end
    # render partial
    [caller_dir, controller_dir, controller_partials_dir, global_partials_dir, root_dir].each do |dir|
      partials.each do |partial|
        path = "#{dir}/#{partial}"
        return render(file: path, locals: locals) if File.file?(path)
      end
    end
    raise ArgumentError, "could not render any of the partials #{partials} in #{caller_dir}" if options[:optional_partial] != true
  end

end
