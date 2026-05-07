# frozen_string_literal: true

source 'https://rubygems.org'

# This will now accept 3.3.0, 3.3.11, etc., but will stop before 3.4.0
ruby '~> 3.3.0'

gem 'activerecord', '~> 7.1'
gem 'rake', '~> 13.0'
gem 'sqlite3', '~> 1.6'
gem 'standalone_migrations', '~> 7.1'

# API
gem 'sinatra', '~> 4.0'
gem 'sinatra-contrib', '~> 4.0'  # Helpful extensions
gem 'puma', '~> 6.4'  # Web server
gem 'rack', '~> 3.0'

# Background Jobs (NEW!)
gem 'sidekiq', '~> 7.2'
gem 'redis', '~> 5.0'

# Email (NEW!)
gem 'mail', '~> 2.8'

# Environment Variables
gem 'dotenv', '~> 3.1'

group :test do
  gem 'rspec', '~> 3.13'
  gem 'simplecov', '~> 0.22', require: false
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'rack-test', '~> 2.1'
  gem 'rspec-sidekiq', '~> 5.0' 
end

group :development, :test do
  gem 'pry', '~> 0.14'
  gem 'rubocop', '~> 1.60', require: false
  gem 'rubocop-rspec', '~> 3.0', require: false
end
