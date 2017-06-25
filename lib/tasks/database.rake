namespace :database do
  desc "Update database schema"
  task :schema do
    Rake::Task["environment"].invoke
    ApplicationDatabase.database_configuration.manage.update_schema
  end

  desc "Create database database"
  task :create do |_, params|
    Rake::Task["environment"].invoke
    ApplicationDatabase.database_configuration.manage.create
  end

  desc "Drop database database"
  task :drop do |_, params|
    Rake::Task["environment"].invoke
    ApplicationDatabase.database_configuration.manage.drop
  end

  desc "Migrate database database"
  task :migrate, :force do |_, params|
    Rake::Task["environment"].invoke
    ApplicationDatabase.database_configuration.manage.migrate params[:force]
  end

  desc "Rollback database database"
  task :rollback do |_, params|
    Rake::Task["environment"].invoke
    ApplicationDatabase.database_configuration.manage.rollback
  end

  desc "Reset database database"
  task :reset do |_, params|
    Rake::Task["database:drop"].reinvoke
    Rake::Task["database:create"].reinvoke
  end
end
