# frozen_string_literal: true

require_relative '../application'
require_relative '../../jobs/booking_confirmation_job'

module API
  class BookingsController < Application
    # GET /api/v1/bookings
    get '/' do
      bookings = Booking.order(created_at: :desc)
      json BookingSerializer.collection(bookings)
    end

    # GET /api/v1/bookings/:id
    get '/:id' do
      booking = Booking.find(params[:id])
      json BookingSerializer.new(booking).as_json
    end

    # POST /api/v1/bookings
    post '/' do
      booking_params = json_params
      
      booking = Booking.create!(
        email: booking_params[:email],
        seats_reserved: booking_params[:seats_reserved],
        total_price_amount: booking_params[:total_price_amount],
        total_price_currency: booking_params[:total_price_currency] || 'USD',
        ticket_type: booking_params[:ticket_type],
        event_id: booking_params[:event_id]
      )

      # Queue background job - this is THE KEY CHANGE! ⚡
      BookingConfirmationJob.perform_async(booking.id)

      status 201
      json BookingSerializer.new(booking).as_json
    end
  end
end