console do
  Rails::ConsoleMethods.send(:define_method, :reload) do
    save_history
    Rails.logger.level = Logger::INFO
    puts "reloading"
    exec "cd #{Rails.root} && rails console"
  end

  Rails::ConsoleMethods.send(:alias_method, :reload!, :reload)

  Rails::ConsoleMethods.send(:define_method, :save_history) do
    if num = IRB.conf[:SAVE_HISTORY] and (num = num.to_i) > 0
      if history_file = IRB.conf[:HISTORY_FILE]
        history_file = File.expand_path(history_file)
      end
      history_file = IRB.rc_file("_history") unless history_file
      hist = IRB::HistorySavingAbility::HISTORY.to_a
      hist = hist[-num..-1] || hist
      open(history_file, 'w') { |f| f.puts hist }
      puts "saving history"
    end
  end
end
