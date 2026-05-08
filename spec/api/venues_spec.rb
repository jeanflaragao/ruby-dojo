# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require_relative '../../lib/api/application'
require_relative '../../lib/api/controllers/venues_controller'

RSpec.describe 'Venues API', type: :api do
  include Rack::Test::Methods

  def app
    API::VenuesController
  end

  describe 'GET /api/v1/venues' do
    it 'returns all venues' do
      venue1 = Venue.create!(
        name: 'Convention Center',
        address: '123 Main St',
        capacity: 500
      )

      venue2 = Venue.create!(
        name: 'Theater',
        address: '456 Oak Ave',
        capacity: 200
      )

      get '/'

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      
      # Should be ordered by name
      expect(json.first[:name]).to eq('Convention Center')
      expect(json.second[:name]).to eq('Theater')
    end

    it 'returns empty array when no venues exist' do
      get '/'

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json).to eq([])
    end
  end

  describe 'GET /api/v1/venues/:id' do
    it 'returns a specific venue' do
      venue = Venue.create!(
        name: 'Convention Center',
        address: '123 Main St',
        capacity: 500
      )

      get "/#{venue.id}"

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:id]).to eq(venue.id)
      expect(json[:name]).to eq('Convention Center')
      expect(json[:address]).to eq('123 Main St')
      expect(json[:capacity]).to eq(500)
    end

    it 'includes events when requested' do
      venue = Venue.create!(
        name: 'Convention Center',
        address: '123 Main St',
        capacity: 500
      )

      event = Event.create!(
        name: 'RubyConf',
        description: 'Ruby conference',
        venue: venue,
        start_time: Time.now + 1.day,
        end_time: Time.now + 1.day + 8.hours,
        total_seats: 100,
        base_price: Money.new(50, 'USD')
      )

      get "/#{venue.id}"

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:events]).to be_an(Array)
      expect(json[:events].length).to eq(1)
      expect(json[:events].first[:name]).to eq('RubyConf')
    end

    it 'returns 404 when venue not found' do
      get '/99999'

      expect(last_response.status).to eq(404)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:error][:type]).to eq('not_found')
    end
  end

  describe 'POST /api/v1/venues' do
    it 'creates a new venue' do
      post '/', {
        name: 'New Venue',
        address: '789 Pine St',
        capacity: 300
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(201)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:name]).to eq('New Venue')
      expect(json[:address]).to eq('789 Pine St')
      expect(json[:capacity]).to eq(300)
      expect(Venue.count).to eq(1)
    end

    it 'returns 422 when validation fails' do
      post '/', {
        name: '',  # Invalid - required
        address: '123 St',
        capacity: 100
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(422)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:error][:type]).to eq('validation_error')
      expect(json[:error][:details][:name]).to include("can't be blank")
    end

    it 'returns 422 when capacity is invalid' do
      post '/', {
        name: 'Test Venue',
        address: '123 St',
        capacity: -10  # Invalid - must be positive
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(422)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:error][:type]).to eq('validation_error')
    end

    it 'returns 400 when JSON is invalid' do
      post '/', 'not valid json', { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(400)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:error][:type]).to eq('invalid_json')
    end
  end

  describe 'PUT /api/v1/venues/:id' do
    it 'updates an existing venue' do
      venue = Venue.create!(
        name: 'Old Name',
        address: '123 Main St',
        capacity: 500
      )

      put "/#{venue.id}", {
        name: 'Updated Name',
        address: '456 New St',
        capacity: 600
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:name]).to eq('Updated Name')
      expect(json[:address]).to eq('456 New St')
      expect(json[:capacity]).to eq(600)
      
      expect(venue.reload.name).to eq('Updated Name')
    end

    it 'allows partial updates' do
      venue = Venue.create!(
        name: 'Venue Name',
        address: '123 Main St',
        capacity: 500
      )

      put "/#{venue.id}", {
        name: 'New Name'
        # address and capacity not provided
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body, symbolize_names: true)
      expect(json[:name]).to eq('New Name')
      expect(json[:address]).to eq('123 Main St')  # Unchanged
      expect(json[:capacity]).to eq(500)  # Unchanged
    end

    it 'returns 404 when venue not found' do
      put '/99999', {
        name: 'Updated'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(404)
    end

    it 'returns 422 when validation fails' do
      venue = Venue.create!(
        name: 'Venue',
        address: '123 St',
        capacity: 500
      )

      put "/#{venue.id}", {
        name: '',  # Invalid
        capacity: -5  # Invalid
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(422)
    end
  end

  describe 'DELETE /api/v1/venues/:id' do
    it 'deletes a venue' do
      venue = Venue.create!(
        name: 'Venue to Delete',
        address: '123 Main St',
        capacity: 500
      )

      delete "/#{venue.id}"

      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
      expect(Venue.exists?(venue.id)).to be false
    end

    it 'returns 404 when venue not found' do
      delete '/99999'

      expect(last_response.status).to eq(404)
    end
  end
end