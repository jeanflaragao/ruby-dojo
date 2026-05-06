# frozen_string_literal: true

# IMPORTANT: Load in this order!

# 1. Database connection first
require_relative 'lib/models/application_record'

# 2. Load all models
Dir[File.join(__dir__, 'lib', 'models', '*.rb')].sort.each { |f| require f }

# 3. Load value objects
Dir[File.join(__dir__, 'lib', 'value_objects', '*.rb')].sort.each { |f| require f }

# 4. Load serializers (depends on models and value objects)
Dir[File.join(__dir__, 'lib', 'serializers', '*.rb')].sort.each { |f| require f }

# 5. Load services
Dir[File.join(__dir__, 'lib', 'services', '*.rb')].sort.each { |f| require f }

# 6. Load API
require_relative 'lib/api/application'
require_relative 'lib/api/controllers/events_controller'
require_relative 'lib/api/controllers/venues_controller'

# 7. Set up routes
require 'rack'

api_app = Rack::URLMap.new(
  '/api/v1/events' => API::EventsController,
  '/api/v1/venues' => API::VenuesController,
  '/' => API::Application
)

run api_app