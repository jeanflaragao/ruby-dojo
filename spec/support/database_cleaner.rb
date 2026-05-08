
require 'database_cleaner/active_record'

RSpec.configure do |config|
  config.before(:suite) do
    # Use :deletion instead of :truncation for SQLite3 compatibility
    DatabaseCleaner.clean_with(:deletion)
  end

  config.before(:each) do
    # Transactions are much faster for individual tests
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end