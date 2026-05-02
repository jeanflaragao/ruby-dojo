# frozen_string_literal: true

source 'https://rubygems.org'

# This will now accept 3.3.0, 3.3.11, etc., but will stop before 3.4.0
ruby '~> 3.3.0'

group :test do
  gem 'rspec', '~> 3.13'
  gem 'simplecov', '~> 0.22', require: false
end

group :development, :test do
  gem 'pry', '~> 0.14'
  gem 'rubocop', '~> 1.60', require: false
  gem 'rubocop-rspec', '~> 3.0', require: false # <-- Change this line
end
