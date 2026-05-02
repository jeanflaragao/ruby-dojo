# frozen_string_literal: true

class Event
  attr_accessor :available_seats
  attr_reader :name, :description, :venue, :start_time, :end_time, :total_seats

  def initialize(name:, description:, venue:, start_time:, end_time:, total_seats:)
    validate_required_fields(name: name, total_seats: total_seats)
    validate_business_rules(start_time: start_time, end_time: end_time, total_seats: total_seats, venue: venue)

    @name = name
    @description = description
    @venue = venue
    @start_time = start_time
    @end_time = end_time
    @total_seats = total_seats
    @available_seats = total_seats
  end

  def duration_in_hours
    (end_time - start_time).fdiv(3600)
  end

  def to_s
    "Event: #{name} at #{venue.name} (#{start_time.strftime('%Y-%m-%d')} - #{end_time.strftime('%Y-%m-%d')})"
  end

  def reserve_seats(number)
    raise ArgumentError, 'must reserve at least 1 seat' unless number.positive?
    raise ArgumentError, 'not enough seats available' if number > available_seats

    # This single line subtracts the number, updates the instance variable,
    # AND automatically returns the new total since it is the last line!
    @available_seats -= number
    number
  end

  def sold_out?
    available_seats <= 0
  end

  private

  def validate_required_fields(name:, total_seats:)
    raise ArgumentError, 'name is required' if name.nil? || name.empty?
    raise ArgumentError, 'name must be at least 3 characters long' if name.length < 3
    raise ArgumentError, 'name must be at most 100 characters long' if name.length > 100
    raise ArgumentError, 'total_seats is required' if total_seats.nil?
  end

  def validate_business_rules(start_time:, end_time:, total_seats:, venue:)
    raise ArgumentError, 'end_time must be after start_time' if end_time <= start_time
    raise ArgumentError, 'total_seats must be positive' unless total_seats.positive?
    raise ArgumentError, 'total_seats exceeds venue capacity' if total_seats > venue.capacity
  end
end
