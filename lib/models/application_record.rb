# frozen_string_literal: true

require 'active_record'
require 'yaml'
require 'erb'

# Base class for all ActiveRecord models
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Load database configuration and connect
  def self.establish_db_connection
    db_config = YAML.safe_load(
      ERB.new(File.read('config/database.yml')).result,
      aliases: true
    )
    env = ENV['RAILS_ENV'] || 'development'
    establish_connection(db_config[env])
  end
end

# Auto-connect when this file is loaded
ApplicationRecord.establish_db_connection