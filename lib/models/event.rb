# frozen_string_literal: true

require_relative '../concerns/validatable'
require_relative '../concerns/timestampable'
require_relative '../softdeletable'
require_relative '../serializable'
require_relative '../loggable'

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
  # Comparable - allows comparison of events (e.g., by start_time)
  include Validatable
  include Timestampable
  include Comparable
  include SoftDeletable
  include Serializable
  prepend Loggable

  # WHY include multiple modules? Each adds different behavior
  # Order matters! Last included can override previous
  # Check with: Event.ancestors
  serializable_attributes :name, :description, :start_time, :end_time, :total_seats, :venue
  attr_accessor :available_seats
  attr_reader :name, :description, :venue, :start_time, :end_time, :total_seats, :base_price

  def initialize(name:, description:, venue:, start_time:, end_time:, total_seats:, base_price: nil)
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
    @base_price = base_price
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

    raise ArgumentError, 'not enough seats available' unless number <= available_seats

    @available_seats -= number
    touch  # Update timestamp (from Timestampable)
    number
  end

  def sold_out?
    available_seats <= 0
  end

  def <=>(other)
    return nil unless other.is_a?(Event)

    start_time <=> other.start_time
  end

  def save(name:)
    @name = name
    touch
  end

  def update(name:)
    @name = name
    touch
  end

  def delete
    super  # Call SoftDeletable#delete
    touch  # Update timestamp
  end

  def self.from_json(json_string)
    hash = JSON.parse(json_string, symbolize_names: true)
    venue_data = hash.delete(:venue)
    venue = Venue.from_json(venue_data) if venue_data # ← remove .to_json
    new(**hash, venue: venue)
  end

  def ticket_price(ticket_type_sym)
    ticket = build_ticket_type(ticket_type_sym)
    ticket.price
  end

  private

  def build_ticket_type(type_sym)
    case type_sym
    when :vip then VIPTicket.new(base_price)
    when :general then GeneralTicket.new(base_price)
    when :student then StudentTicket.new(base_price)
    else raise ArgumentError, "Unknown ticket type: #{type_sym}"
    end
  end

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
