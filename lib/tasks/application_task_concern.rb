# reinvoke method
module Rake
  class Task

    # auto-reenable tasks
    def reinvoke(*params, &block)
      invoke(*params, &block)
      reenable
    end

    # clear namspace of tasks
    class << self
      def clear_namespace(namespace)
        tasks.each do |task|
          task.clear if task.name.match(/\A#{namespace}:/) || task.name.match(/\A#{namespace}\z/)
        end
      end
    end
  end
end

module ApplicationTaskConcern

  # execute system command
  def system_execute(command, options = {})
    options = options.with_indifferent_access
    puts options[:message] || "Executing: #{command.to_s.green}" if options[:silent] != true
    `#{command}`
  end

end
