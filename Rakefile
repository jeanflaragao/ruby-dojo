require 'bundler/setup'
require 'standalone_migrations'

StandaloneMigrations::Tasks.load_tasks

# Custom task to setup database for tests
namespace :db do
  desc 'Setup test database'
  task :test_prepare do
    ENV['RACK_ENV'] = 'test'
    Rake::Task['db:migrate'].invoke
  end
end
