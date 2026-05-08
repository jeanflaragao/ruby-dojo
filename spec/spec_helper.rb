# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

# ============================================================================
# CODE COVERAGE (SimpleCov)
# ============================================================================
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/config/'
  minimum_coverage 100
  enable_coverage :branch
end

# ============================================================================
# TEST DEPENDENCIES
# ============================================================================
require 'sidekiq/testing'
require 'database_cleaner/active_record'
require 'factory_bot'

# ============================================================================
# LOAD APPLICATION CODE
# ============================================================================

# 1. Load ApplicationRecord first (since other models inherit from it)
require_relative '../lib/models/application_record'

# 2. Load all other Ruby files in the lib/ directory
Dir[File.join(__dir__, '..', 'lib', '**', '*.rb')].each do |file|
  # Skip application_record.rb since we already loaded it
  require file unless file.end_with?('application_record.rb')
end

# ============================================================================
# RSPEC CONFIGURATION
# ============================================================================

RSpec.configure do |config|
  # ============================================================================
  # EXPECTATION & MOCK CONFIGURATION
  # ============================================================================
  
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # ============================================================================
  # TEST BEHAVIOR
  # ============================================================================
  
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed

  # Show detailed output when running single test
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  # Show slowest examples (useful for optimization)
  config.profile_examples = 10

  # ============================================================================
  # FACTORYBOT CONFIGURATION
  # ============================================================================
  
  # Include FactoryBot methods (create, build, build_stubbed, etc.)
  config.include FactoryBot::Syntax::Methods

  # Load factory definitions before test suite runs
  config.before(:suite) do
    FactoryBot.definition_file_paths = [File.expand_path('factories', __dir__)]
    FactoryBot.find_definitions
  end

  # Lint factories to catch errors early (optional, but recommended)
  # Uncomment to enable factory linting in CI/CD:
  # config.before(:suite) do
  #   FactoryBot.lint(verbose: true) if ENV['LINT_FACTORIES']
  # end

  # ============================================================================
  # DATABASE CLEANER CONFIGURATION
  # ============================================================================
  
  # Setup DatabaseCleaner before suite
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  # Clean database around each test
  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Use truncation for integration tests (handles threads/connections better)
  config.before(:each, type: :integration) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each, type: :integration) do
    DatabaseCleaner.strategy = :transaction
  end

  # ============================================================================
  # SIDEKIQ CONFIGURATION
  # ============================================================================
  
  # Clear all Sidekiq jobs before each test
  config.before(:each) do
    Sidekiq::Job.clear_all
  end

  # For tests that need inline job execution, use:
  # around(:each, type: :job) do |example|
  #   Sidekiq::Testing.inline! do
  #     example.run
  #   end
  # end
end

# ============================================================================
# HELPER METHODS (Optional - uncomment if needed)
# ============================================================================

# def json_response
#   JSON.parse(response.body)
# end

# def auth_headers(user)
#   { 'Authorization' => "Bearer #{user.token}" }
# end