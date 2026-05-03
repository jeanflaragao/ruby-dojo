# frozen_string_literal: true

require 'date'

# DateRange value object - Immutable representation of date ranges
# Prevents primitive obsession and provides domain-specific operations
#
# Example:
#   event_dates = DateRange.new(Date.today, Date.today + 7)
#   event_dates.overlaps?(booking_dates)
class DateRange
  attr_reader :start_date, :end_date

  def initialize(start_date, end_date)
    raise ArgumentError, 'Start date must be before or equal to end date' if start_date > end_date

    @start_date = start_date
    @end_date = end_date
    freeze
  end

  # Duration calculations
  def days
    (end_date - start_date).to_i + 1 # Inclusive
  end

  def weeks
    days / 7
  end

  # Check if a date falls within this range (inclusive)
  def includes?(date)
    date.between?(start_date, end_date)
  end

  # Check if two date ranges overlap
  def overlaps?(other)
    start_date <= other.end_date && end_date >= other.start_date
  end

  # Equality based on dates
  def ==(other)
    return false unless other.is_a?(DateRange)

    start_date == other.start_date && end_date == other.end_date
  end

  alias eql? ==

  def hash
    [start_date, end_date].hash
  end

  # Formatting
  def to_s
    "#{start_date} to #{end_date}"
  end

  def to_h
    {
      start_date: start_date,
      end_date: end_date,
      days: days
    }
  end
end
