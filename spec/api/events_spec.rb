# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require_relative '../../lib/api/application'
require_relative '../../lib/api/controllers/events_controller'

RSpec.describe 'Events API', type: :api do
  include Rack::Test::Methods

  def app
    API::EventsController
  end

  let(:venue) do
    Venue.create!(
      name: 'Convention Center',
      address: '123 Main St',
      capacity: 500
    )
  end

  describe 'GET /api/v1/events' do
    it 'returns all events' do
      Event.create!(
        name: 'RubyConf',
        description: 'Ruby conference',
        venue: venue,
        start_time: Time.now + 1.day,
        end_time: Time.now + 1.day + 8.hours,
        total_seats: 100,
        base_price: Money.new(50, 'USD')
      )

      Event.create!(
        name: 'RailsConf',
        description: 'Rails conference',
        venue: venue,
        start_time: Time.now + 2.days,
        end_time: Time.now + 2.days + 8.hours,
        total_seats: 200,
        base_price: Money.new(75, 'USD')
      )

      get '/'

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.first[:name]).to eq('RubyConf')
    end

    it 'returns empty array when no events exist' do
      get '/'

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json).to eq([])
    end
  end

  describe 'GET /api/v1/events/:id' do
    it 'returns a specific event' do
      event = Event.create!(
        name: 'RubyConf',
        description: 'Ruby conference',
        venue: venue,
        start_time: Time.now + 1.day,
        end_time: Time.now + 1.day + 8.hours,
        total_seats: 100,
        base_price: Money.new(50, 'USD')
      )

      get "/#{event.id}"

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:id]).to eq(event.id)
      expect(json[:name]).to eq('RubyConf')
      expect(json[:venue][:name]).to eq('Convention Center')
    end

    it 'returns 404 when event not found' do
      get '/99999'

      expect(last_response.status).to eq(404)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:error][:type]).to eq('not_found')
    end
  end

  describe 'POST /api/v1/events' do
    it 'creates a new event' do
      post '/', {
        name: 'RubyConf',
        description: 'Ruby conference',
        venue_id: venue.id,
        start_time: (Time.now + 1.day).iso8601,
        end_time: (Time.now + 1.day + 8.hours).iso8601,
        total_seats: 100,
        base_price: { amount: 50, currency: 'USD' }
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(201)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:name]).to eq('RubyConf')
      expect(Event.count).to eq(1)
    end

    it 'returns 422 when validation fails' do
      post '/', {
        name: '',  # Invalid!
        venue_id: venue.id
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(422)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:error][:type]).to eq('validation_error')
    end
  end

  describe 'PUT /api/v1/events/:id' do
    it 'updates an existing event' do
      event = Event.create!(
        name: 'RubyConf',
        description: 'Ruby conference',
        venue: venue,
        start_time: Time.now + 1.day,
        end_time: Time.now + 1.day + 8.hours,
        total_seats: 100,
        base_price: Money.new(50, 'USD')
      )

      put "/#{event.id}", {
        name: 'RubyConf 2026'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:name]).to eq('RubyConf 2026')
      expect(event.reload.name).to eq('RubyConf 2026')
    end
  end

  describe 'DELETE /api/v1/events/:id' do
    it 'deletes an event' do
      event = Event.create!(
        name: 'RubyConf',
        description: 'Ruby conference',
        venue: venue,
        start_time: Time.now + 1.day,
        end_time: Time.now + 1.day + 8.hours,
        total_seats: 100,
        base_price: Money.new(50, 'USD')
      )

      delete "/#{event.id}"

      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
      expect(Event.exists?(event.id)).to be false
    end
  end
end