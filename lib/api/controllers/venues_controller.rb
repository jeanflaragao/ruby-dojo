# frozen_string_literal: true

require_relative '../application'

module API
  class VenuesController < Application
    # GET /api/v1/venues
    get '/' do
      venues = Venue.order(:name)
      json VenueSerializer.collection(venues)
    end

    # GET /api/v1/venues/:id
    get '/:id' do
      venue = Venue.find(params[:id])
      json VenueSerializer.new(venue).as_json(include_events: true)
    end

    # POST /api/v1/venues
    post '/' do
      params = json_params
      
      venue = Venue.create!(
        name: params[:name],
        address: params[:address],
        capacity: params[:capacity]
      )

      status 201
      json VenueSerializer.new(venue).as_json
    end

    # PUT /api/v1/venues/:id
    put '/:id' do
      venue = Venue.find(params[:id])
      update_params = json_params

      # Only update attributes that are present in request
      venue.update!(update_params.slice(:name, :address, :capacity).compact)

      json VenueSerializer.new(venue).as_json
    end

    # DELETE /api/v1/venues/:id
    delete '/:id' do
      venue = Venue.find(params[:id])
      venue.destroy!

      status 204
    end
  end
end