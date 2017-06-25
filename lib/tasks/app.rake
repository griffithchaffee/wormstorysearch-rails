namespace :app do
  desc "Eager load application and environment"
  task :load do
    Rake::Task["environment"].invoke
    Rails.application.eager_load!
  end
end
