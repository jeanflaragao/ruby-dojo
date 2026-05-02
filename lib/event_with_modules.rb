# frozen_string_literal: true

require_relative 'validatable'
require_relative 'timestampable'

# Event - Refactored to use modules
#
# CHANGES FROM PREVIOUS VERSION:
# - Now includes Validatable module (DRY validation)
# - Now includes Timestampable module (automatic timestamps)
# - Simplified validation methods (use module methods)
#
# DEMONSTRATION OF:
# - Multiple module inclusion
# - Module method usage
# - Composition over duplication

class Event
  # MODULES INCLUDED:
  # Validatable - provides validate_name, validate_positive, etc.
  # Timestampable - provides created_at, updated_at, touch
  include Validatable
  include Timestampable

  # WHY include multiple modules? Each adds different behavior
  # Order matters! Last included can override previous
  # Check with: Event.ancestors

  attr_accessor :available_seats
  attr_reader :name, :description, :venue, :start_time, :end_time, :total_seats

  def initialize(name:, description:, venue:, start_time:, end_time:, total_seats:)
    # Use Validatable module methods!
    validate_required_fields(name: name, total_seats: total_seats)
    validate_business_rules(start_time: start_time, end_time: end_time, total_seats: total_seats, venue: venue)

    @name = name
    @description = description
    @venue = venue
    @start_time = start_time
    @end_time = end_time
    @total_seats = total_seats
    @available_seats = total_seats

    # Use Timestampable module method!
    set_timestamps
  end

  def duration_in_hours
    (end_time - start_time).fdiv(3600)
  end

  def to_s
    "Event: #{name} at #{venue.name} (#{start_time.strftime('%Y-%m-%d')} - #{end_time.strftime('%Y-%m-%d')})"
  end

  def reserve_seats(number)
    validate_positive(number, field_name: 'seat count')
    
    unless number <= available_seats
      raise ArgumentError, 'not enough seats available'
    end

    @available_seats -= number
    touch  # Update timestamp (from Timestampable)
    number
  end

  def sold_out?
    available_seats <= 0
  end

  private

  def validate_required_fields(name:, total_seats:)
    # Use module methods instead of duplicating logic!
    validate_name(name) # from Validatable
    validate_presence(total_seats, field_name: 'total_seats') # from Validatable
  end

  def validate_business_rules(start_time:, end_time:, total_seats:, venue:)
    validate_time_order(start_time, end_time) # from Validatable
    validate_positive(total_seats, field_name: 'total_seats') # from Validatable

    # Venue capacity check (domain-specific logic stays in class)
    raise ArgumentError, 'total_seats exceeds venue capacity' unless total_seats <= venue.capacity
  end
end

# ============================================================================
# BEFORE vs AFTER
# ============================================================================
#
# BEFORE (without modules):
#   def validate_required_fields(name:, total_seats:)
#     raise ArgumentError, 'name is required' if name.nil? || name.empty?
#     raise ArgumentError, 'name must be at least 3 characters' if name.length < 3
#     raise ArgumentError, 'name must be at most 100 characters' if name.length > 100
#     raise ArgumentError, 'total_seats is required' if total_seats.nil?
#   end
#
# AFTER (with Validatable module):
#   def validate_required_fields(name:, total_seats:)
#     validate_name(name)  # Module method!
#     validate_presence(total_seats, field_name: 'total_seats')
#   end
#
# BENEFITS:
# - Less code in Event class
# - Validation logic centralized in Validatable
# - Same validation can be used in Venue, User, etc.
# - Easy to test (test module once, not every class)
#
# ============================================================================

# ============================================================================
# METHOD LOOKUP CHAIN
# ============================================================================
#
# When you call validate_name on an Event instance, Ruby searches:
# 1. Event class
# 2. Timestampable module (included last)
# 3. Validatable module (included first)
# 4. Object
# 5. BasicObject
#
# Check it yourself:
#   Event.ancestors
#   # => [Event, Timestampable, Validatable, Object, Kernel, BasicObject]
#
# ============================================================================