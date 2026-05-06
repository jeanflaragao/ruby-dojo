# frozen_string_literal: true

require 'active_record'
require 'yaml'

# Load database configuration
db_config_file = File.join(__dir__, 'database.yml')
db_config = YAML.load_file(db_config_file, aliases: true)

# Determine environment
env = ENV['RACK_ENV'] || 'development'

# Connect to database
ActiveRecord::Base.establish_connection(db_config[env])

# Enable logging in development
ActiveRecord::Base.logger = Logger.new($stdout) if env == 'development'
