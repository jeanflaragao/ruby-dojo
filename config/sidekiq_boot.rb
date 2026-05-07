# frozen_string_literal: true

# Load environment
ENV['RAILS_ENV'] ||= 'development'
ENV['RACK_ENV'] = ENV['RAILS_ENV']

# Load gems
require 'bundler/setup'
Bundler.require(:default, ENV['RAILS_ENV'])

# Load database
require_relative '../lib/models/application_record'

# Load all models
Dir[File.join(__dir__, '..', 'lib', 'models', '*.rb')].each { |f| require f }

# Load value objects
Dir[File.join(__dir__, '..', 'lib', 'value_objects', '*.rb')].each { |f| require f }

# Load Sidekiq config
require_relative 'initializers/sidekiq'

# Load mailers
Dir[File.join(__dir__, '..', 'lib', 'mailers', '*.rb')].each { |f| require f }

# Load jobs
Dir[File.join(__dir__, '..', 'lib', 'jobs', '*.rb')].each { |f| require f }

puts "Sidekiq boot complete!"