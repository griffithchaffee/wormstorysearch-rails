module Rake
  class Task

    # auto-reenable tasks
    def reinvoke(*params, &block)
      invoke *params, &block
      reenable
    end

    # clear namspace of tasks
    def self.clear_namespace(namespace)
      tasks.each do |task|
        task.clear if task.name.match(/\A#{namespace}:/) || task.name.match(/\A#{namespace}\z/)
      end
    end

  end
end

module TaskHelper

  def get_multiline_input(terminator)
    input = ""
    while (text = $stdin.gets).strip != terminator
      input << text
    end
    input.strip
  end

  def alias_task(new_task, old_task)
    old_task = Rake::Task[old_task]
    desc old_task.full_comment if old_task.full_comment
    task new_task, *old_task.arg_names do |_, args|
      args = old_task.arg_names.map { |a| args[a] }
      old_task.invoke(args)
    end
  end

  # execute system command
  def execute(command, options = {})
    options = options.with_indifferent_access
    puts options[:message] || "Executing: #{command.to_s.green}" if options[:echo] != false
    `#{command}`
  end

end
