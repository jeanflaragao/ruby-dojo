# frozen_string_literal: true

require_relative '../application'

module API
  class EventsController < Application
    # GET /api/v1/events
    get '/' do
      events = Event.includes(:venue).order(start_time: :asc)
      json EventSerializer.collection(events, include_venue: false)
    end

    # GET /api/v1/events/:id
    get '/:id' do
      event = Event.includes(:venue).find(params[:id])
      json EventSerializer.new(event).as_json(include_venue: true)
    end

    # POST /api/v1/events
    post '/' do
      params = json_params
      
      # Parse Money from params
      base_price = if params[:base_price]
        Money.new(
          params[:base_price][:amount],
          params[:base_price][:currency] || 'USD'
        )
      end

      event = Event.create!(
        name: params[:name],
        description: params[:description],
        venue_id: params[:venue_id],
        start_time: params[:start_time],
        end_time: params[:end_time],
        total_seats: params[:total_seats],
        base_price: base_price
      )

      status 201
      json EventSerializer.new(event).as_json(include_venue: true)
    end

    # PUT /api/v1/events/:id
    put '/:id' do
      event = Event.find(params[:id])
      update_params = json_params

      # Handle Money separately if provided
      if update_params[:base_price]
        base_price = Money.new(
          update_params[:base_price][:amount],
          update_params[:base_price][:currency] || 'USD'
        )
        event.base_price = base_price
        update_params.delete(:base_price)
      end

      # Update other attributes (only those provided)
      allowed_params = update_params.slice(:name, :description, :venue_id, :start_time, :end_time, :total_seats, :available_seats)
      event.update!(allowed_params.compact) unless allowed_params.empty?

      json EventSerializer.new(event).as_json(include_venue: true)
    end

    # DELETE /api/v1/events/:id
    delete '/:id' do
      event = Event.find(params[:id])
      event.destroy!

      status 204
    end
  end
end