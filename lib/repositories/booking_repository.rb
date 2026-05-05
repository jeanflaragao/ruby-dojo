# frozen_string_literal: true

require_relative '../value_objects/money'

class BookingRepository
  def initialize(bookings = [])
    @bookings = bookings.dup
  end

  def add(booking)
    @bookings << booking
  end

  def all
    @bookings.dup
  end

  def find_by_id(booking_id)
    @bookings.find { |b| b.booking_id == booking_id }
  end

  def find_by_email(email)
    @bookings.select { |b| b.email == email }
  end

  def total_revenue
    return Money.new(0, 'USD') if @bookings.empty?

    currency = @bookings.first.total_price.currency
    total_amount = @bookings.sum { |b| b.total_price.amount }

    Money.new(total_amount, currency)
  end

  def bookings_for_event(event_name)
    @bookings.select { |b| b.event.name == event_name }
  end
end
