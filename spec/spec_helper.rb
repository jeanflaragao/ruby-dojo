# frozen_string_literal: true
ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  minimum_coverage 100
  enable_coverage :branch
end

require 'database_cleaner/active_record'

# 1. Load ApplicationRecord first (since other models inherit from it)
require_relative '../lib/models/application_record'

# 2. Load all other Ruby files in the lib/ directory
Dir[File.join(__dir__, '..', 'lib', '**', '*.rb')].each do |file|
  # Skip application_record.rb since we already loaded it
  require file unless file.end_with?('application_record.rb')
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.order = :random
  Kernel.srand config.seed

  # Database Cleaner configuration
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end