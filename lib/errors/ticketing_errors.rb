# frozen_string_literal: true

# Custom Exception Hierarchy for Ticketing System
#
# WHY? Specific exceptions make error handling more precise
# and error messages more helpful to users
#
# HIERARCHY:
#   TicketingError (base class for all our errors)
#     ├── BookingError (booking-related errors)
#     │   ├── EventSoldOutError
#     │   ├── InsufficientSeatsError
#     │   └── InvalidBookingError
#     ├── ValidationError (validation failures)
#     │   ├── InvalidNameError
#     │   └── InvalidDateError
#     └── NotFoundError (resource not found)
#         ├── EventNotFoundError
#         └── VenueNotFoundError

# Base exception for all our application errors
# WHY inherit from StandardError? It's the right base for application errors
class TicketingError < StandardError
  # Add common behavior for all our errors
  attr_reader :details

  def initialize(message, details = {})
    super(message)
    @details = details
  end

  # Convert to hash for API responses
  def to_h
    {
      error: self.class.name,
      message: message,
      details: details
    }
  end
end

# ============================================================================
# BOOKING ERRORS
# ============================================================================

# Base class for all booking-related errors
class BookingError < TicketingError; end

# Event is completely sold out
class EventSoldOutError < BookingError
  attr_reader :event_name

  def initialize(event_name)
    @event_name = event_name
    super(
      "Event '#{event_name}' is sold out",
      { event: event_name, available_seats: 0 }
    )
  end
end

# Not enough seats for the requested quantity
class InsufficientSeatsError < BookingError
  attr_reader :available, :requested

  def initialize(available, requested, event_name: nil)
    @available = available
    @requested = requested
    
    message = "Only #{available} seats available, but #{requested} requested"
    message += " for #{event_name}" if event_name

    super(message, { available: available, requested: requested })
  end
end

# Booking is invalid for business logic reasons
class InvalidBookingError < BookingError
  def initialize(reason)
    super("Invalid booking: #{reason}", { reason: reason })
  end
end

# ============================================================================
# VALIDATION ERRORS
# ============================================================================

# Base class for validation failures
class ValidationError < TicketingError
  attr_reader :field

  def initialize(field, message)
    @field = field
    super("Validation failed for #{field}: #{message}", { field: field })
  end
end

# Specific validation errors
class InvalidNameError < ValidationError
  def initialize(name, constraint)
    super('name', "Name '#{name}' #{constraint}")
  end
end

class InvalidDateError < ValidationError
  def initialize(message)
    super('date', message)
  end
end

# ============================================================================
# NOT FOUND ERRORS
# ============================================================================

# Base class for resource not found errors
class NotFoundError < TicketingError
  attr_reader :resource_type, :identifier

  def initialize(resource_type, identifier)
    @resource_type = resource_type
    @identifier = identifier
    super(
      "#{resource_type} not found: #{identifier}",
      { resource_type: resource_type, identifier: identifier }
    )
  end
end

# Specific not found errors
class EventNotFoundError < NotFoundError
  def initialize(identifier)
    super('Event', identifier)
  end
end

class VenueNotFoundError < NotFoundError
  def initialize(identifier)
    super('Venue', identifier)
  end
end

# ============================================================================
# USAGE EXAMPLES
# ============================================================================
#
# # Raising exceptions:
# raise EventSoldOutError.new('RubyConf 2026')
# raise InsufficientSeatsError.new(5, 10, event_name: 'RailsConf')
# raise EventNotFoundError.new('unknown-event-123')
#
# # Catching specific errors:
# begin
#   book_tickets(event, 100)
# rescue EventSoldOutError => e
#   puts "Sorry, #{e.event_name} is sold out!"
# rescue InsufficientSeatsError => e
#   puts "Only #{e.available} seats left, you requested #{e.requested}"
# rescue BookingError => e
#   puts "Booking failed: #{e.message}"
# end
#
# # Catching all app errors:
# begin
#   some_operation
# rescue TicketingError => e
#   logger.error(e.to_h)
#   render json: e.to_h, status: :unprocessable_entity
# end
#
# ============================================================================

# ============================================================================
# ERROR HIERARCHY BENEFITS
# ============================================================================
#
# 1. SPECIFICITY
#    - Catch EventSoldOutError specifically for sold-out handling
#    - Catch BookingError for all booking failures
#    - Catch TicketingError for all app errors
#
# 2. ADDITIONAL DATA
#    - EventSoldOutError carries event_name
#    - InsufficientSeatsError carries available and requested
#    - NotFoundError carries resource_type and identifier
#
# 3. API RESPONSES
#    - to_h method provides structured error data
#    - Easy to convert to JSON for API responses
#
# 4. LOGGING
#    - details hash provides context for debugging
#    - Error class name shows exactly what failed
#
# 5. USER MESSAGES
#    - Specific error messages help users understand what went wrong
#    - Can show "Only 5 seats left" instead of generic "Booking failed"
#
# ============================================================================