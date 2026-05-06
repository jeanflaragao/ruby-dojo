# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'json'

module API
  class Application < Sinatra::Base
    # Configuration
    configure :development do
      set :show_exceptions, :after_handler  # CHANGED THIS!
      set :dump_errors, true                # ADD THIS!
    end
    
    configure :production do
      set :show_exceptions, false
      set :raise_errors, false
    end

    configure do
      set :show_exceptions, false
      set :raise_errors, false
    end

    # Load database connection
    before do
      content_type :json
    end

    # Health check endpoint
    get '/health' do
      json status: 'ok', timestamp: Time.now.iso8601
    end

    # 404 Handler
    not_found do
      json error: {
        type: 'not_found',
        message: 'The requested resource was not found'
      }
    end

    # 500 Handler
    error do
      json error: {
        type: 'internal_error',
        message: 'An internal error occurred'
      }
    end

    # ActiveRecord errors
    error ActiveRecord::RecordNotFound do
      status 404
      json error: {
        type: 'not_found',
        message: env['sinatra.error'].message
      }
    end

    error ActiveRecord::RecordInvalid do
      status 422
      json error: {
        type: 'validation_error',
        message: 'Validation failed',
        details: env['sinatra.error'].record.errors.messages
      }
    end

    # Helper methods
    helpers do
      def json_params
        JSON.parse(request.body.read, symbolize_names: true)
      rescue JSON::ParserError
        halt 400, json(error: { type: 'invalid_json', message: 'Invalid JSON in request body' })
      end
    end
  end
end