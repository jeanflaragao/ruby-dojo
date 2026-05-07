# frozen_string_literal: true

class BookingSerializer
  def initialize(booking)
    @booking = booking
  end

  def as_json(options = {})
    {
      id: @booking.id,
      confirmation_code: @booking.confirmation_code,
      seats_reserved: @booking.seats_reserved,
      total_price: {
        amount: format('%.2f', @booking.total_price_amount),
        currency: @booking.total_price_currency
      },
      email: @booking.email,
      created_at: @booking.created_at.iso8601
    }
  end

  def self.collection(bookings, options = {})
    bookings.map { |booking| new(booking).as_json(options) }
  end
end