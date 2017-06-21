# https://github.com/puma/puma/blob/master/examples/config.rb
ENV["LOG_TO_STDOUT"] = "true"

puma_config = {}.tap do |config|
  config[:bind]         = "tcp://0.0.0.0:8080"
  config[:environment]  = "development"
  config[:thread_count] = 1
  config[:worker_count] = nil
  config[:pid_file]     = "#{File.dirname(File.dirname(File.expand_path(__FILE__)))}/tmp/pids/puma.pid"
end

puma_config = Struct.new(*puma_config.keys).new(*puma_config.values)

# core
bind(puma_config.bind)
environment(puma_config.environment)
threads(puma_config.thread_count, puma_config.thread_count)
workers(puma_config.worker_count)
pidfile(puma_config.pid_file)
preload_app!
