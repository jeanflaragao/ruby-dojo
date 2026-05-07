# frozen_string_literal: true

# Load gems
require 'securerandom'
require 'rack/session/cookie'
require 'bundler/setup'
Bundler.require(:default, ENV.fetch('RACK_ENV', 'development'))

# Set environment
ENV['RACK_ENV'] ||= 'development'
ENV['RAILS_ENV'] = ENV['RACK_ENV']
secret_key = ENV['SESSION_SECRET'] || SecureRandom.hex(32)
use Rack::Session::Cookie, secret: secret_key, same_site: true, max_age: 86400

# Database connection
require_relative 'lib/models/application_record'

# Load models
Dir[File.join(__dir__, 'lib', 'models', '*.rb')].sort.each { |f| require f }

# Load value objects
Dir[File.join(__dir__, 'lib', 'value_objects', '*.rb')].sort.each { |f| require f }

# Load serializers
Dir[File.join(__dir__, 'lib', 'serializers', '*.rb')].sort.each { |f| require f }

# Load services
Dir[File.join(__dir__, 'lib', 'services', '*.rb')].sort.each { |f| require f }

# Load Sidekiq
require_relative 'config/initializers/sidekiq'

# Load jobs
Dir[File.join(__dir__, 'lib', 'jobs', '*.rb')].sort.each { |f| require f }

# 6. Load API
require_relative 'lib/api/application'
require_relative 'lib/api/controllers/events_controller'
require_relative 'lib/api/controllers/venues_controller'
require_relative 'lib/api/controllers/bookings_controller'

# Sidekiq Web UI
require 'sidekiq/web'

# Set up routes
require 'rack'

api_app = Rack::URLMap.new(
  '/api/v1/events' => API::EventsController,
  '/api/v1/venues' => API::VenuesController,
  '/api/v1/bookings' => API::BookingsController,
  '/sidekiq' => Sidekiq::Web,
  '/' => API::Application
)

run api_app