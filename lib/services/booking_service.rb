# frozen_string_literal: true

require_relative '../result'
require_relative '../errors/ticketing_errors'
require_relative 'payment_service'

# BookingService - Handles ticket booking with proper error handling
#
# DEMONSTRATES:
# - Service Object pattern (business logic separate from models)
# - Result objects for expected failures (validation, business rules)
# - Exceptions for unexpected failures (system errors)
# - Railway-Oriented Programming (chaining operations)
#
# WHY SERVICE OBJECT?
# - Models should be simple data containers
# - Business logic belongs in services
# - Easier to test complex workflows
# - Single Responsibility Principle
#
# ERROR HANDLING STRATEGY:
# - Use Result for business logic failures (expected)
# - Use Exceptions for system failures (unexpected)
# - Always validate inputs
# - Provide helpful error messages

class BookingService < PaymentService

  # Booking result data structure
  Booking = Struct.new(:event, :seats_reserved, :total_price, :booking_id, :timestamp) do
    def to_h
      {
        booking_id: booking_id,
        event_name: event.name,
        seats_reserved: seats_reserved,
        total_price: total_price,
        timestamp: timestamp
      }
    end
  end

  # Initialize service with repository
  # WHY dependency injection? Makes testing easier (can inject mock repo)
  def initialize(event_repository)
    @repository = event_repository
  end

  # Book tickets using Result pattern (for expected failures)
  #
  # @param event_name [String] name of the event
  # @param requested_seats [Integer] number of seats to book
  # @return [Result<Booking>] Success with booking or Failure with error message
  #
  # WHY Result? Booking failures are EXPECTED (sold out, insufficient seats)
  # Caller should always handle both success and failure cases
  def book(event_name, requested_seats)
    validate_inputs(event_name, requested_seats)
      .flat_map { find_event(event_name) }
      .flat_map { |event| check_seat_availability(event, requested_seats) }
      .flat_map { |event| reserve_seats(event, requested_seats) }
      .flat_map { |event| create_booking(event, requested_seats) }
  end

  # Book tickets using Exceptions (for unexpected failures)
  #
  # @param event_name [String] name of the event
  # @param requested_seats [Integer] number of seats to book
  # @return [Booking] the booking
  # @raise [EventNotFoundError] if event doesn't exist
  # @raise [EventSoldOutError] if event is sold out
  # @raise [InsufficientSeatsError] if not enough seats available
  #
  # WHY Exceptions? Some callers prefer exceptions over Result objects
  # Useful when you want errors to bubble up automatically
  def book!(event_name, requested_seats)
    result = book(event_name, requested_seats)

    if result.success?
      result.value
    else
      # Convert failure to appropriate exception
      raise exception_from_error(result.error)
    end
  end

  def book_with_retry(event_name, requested_seats, max_retries: 3)
    attempt = 0
    
    begin
      attempt += 1
      book!(event_name, requested_seats)
    rescue InsufficientSeatsError => e
      # Don't retry - this is a permanent failure
      raise
    rescue BookingError => e
      if attempt < max_retries
        sleep(0.1 * attempt)  # Exponential backoff
        retry
      else
        raise
      end
    end
  end

  def book_with_payment(event_name, seats, payment_method)
    book(event_name, seats)
      .flat_map { |booking| charge_payment(booking, payment_method) }
      .flat_map { |booking| finalize_booking(booking) }
  end

  def calculate_price_for_user(user, base_price)
    if user.nil?
      base_price
    else
      discount = user.discount_percentage
      base_price * (1 - discount / 100.0)
    end
  end

  private

  # Step 1: Validate inputs
  # WHY first? Fail fast on invalid input
  def validate_inputs(event_name, requested_seats)
    if event_name.nil? || event_name.empty?
      return Result.failure('Event name is required')
    end

    unless requested_seats.is_a?(Integer) && requested_seats.positive?
      return Result.failure('Requested seats must be a positive integer')
    end

    Result.success(true)
  end

  # Step 2: Find the event
  # WHY Result? Event not found is an expected failure
  def find_event(event_name)
    event = @repository.find_by_name(event_name)

    if event
      Result.success(event)
    else
      Result.failure("Event '#{event_name}' not found")
    end
  end

  # Step 3: Check seat availability
  # WHY separate from reservation? Single Responsibility
  def check_seat_availability(event, requested_seats)
    if event.sold_out?
      Result.failure("Event '#{event.name}' is sold out")
    elsif requested_seats > event.available_seats
      Result.failure(
        "Only #{event.available_seats} seats available, but #{requested_seats} requested"
      )
    else
      Result.success(event)
    end
  end

  # Step 4: Reserve the seats
  # WHY Result? Reservation could fail due to race condition
  def reserve_seats(event, requested_seats)
    # This could raise an exception if Event#reserve_seats fails
    # In a real system, this might involve database transactions
    begin
      event.reserve_seats(requested_seats)
      Result.success(event)
    rescue ArgumentError => e
      # Convert exception to Result (defensive programming)
      Result.failure("Reservation failed: #{e.message}")
    end
  end

  # Step 5: Create booking record
  # WHY separate? In real system, this would save to database
  def create_booking(event, seats_reserved)
    booking = Booking.new(
      event,
      seats_reserved,
      calculate_price(seats_reserved),
      generate_booking_id,
      Time.now
    )

    Result.success(booking)
  end

  # Helper: Calculate price
  # WHY hardcoded? In real system, this would come from event pricing
  def calculate_price(seats)
    price_per_seat = 50.0  # $50 per seat
    seats * price_per_seat
  end

  # Helper: Generate booking ID
  # WHY simple? In real system, this would be a UUID or database ID
  def generate_booking_id
    "BOOK-#{Time.now.to_i}-#{rand(1000..9999)}"
  end

  # Convert Result failure to appropriate exception
  # WHY? For book! method that uses exceptions
  def exception_from_error(error_message)
    case error_message
    when /not found/
      event_name = error_message[/'([^']+)'/, 1]
      EventNotFoundError.new(event_name || 'unknown')
    when /sold out/
      event_name = error_message[/'([^']+)'/, 1]
      EventSoldOutError.new(event_name || 'unknown')
    when /Only (\d+) seats available/
      available = error_message[/Only (\d+)/, 1].to_i
      requested = error_message[/(\d+) requested/, 1].to_i
      InsufficientSeatsError.new(available, requested)
    else
      InvalidBookingError.new(error_message)
    end
  end

  def charge_payment(booking, payment_method)
    payment_service = PaymentService.new
    payment_result = payment_service.charge(booking.total_price, payment_method)
    
    if payment_result.success?
      Result.success(booking)
    else
      # Refund seats
      booking.event.reserve_seats(-booking.seats_reserved)
      Result.failure("Payment failed: #{payment_result.error}")
    end
  end
end

# ============================================================================
# USAGE EXAMPLES
# ============================================================================
#
# # Using Result pattern (recommended for most cases):
# service = BookingService.new(event_repository)
# result = service.book('RubyConf 2026', 5)
#
# result
#   .on_success { |booking| puts "Booked! ID: #{booking.booking_id}" }
#   .on_failure { |error| puts "Failed: #{error}" }
#
# # Or with if/else:
# if result.success?
#   booking = result.value
#   send_confirmation_email(booking)
# else
#   log_error(result.error)
# end
#
# # Using Exception pattern (for compatibility or when you want bubbling):
# begin
#   booking = service.book!('RubyConf 2026', 5)
#   send_confirmation_email(booking)
# rescue EventSoldOutError => e
#   puts "Sorry, #{e.event_name} is sold out!"
# rescue InsufficientSeatsError => e
#   puts "Only #{e.available} seats available"
# rescue BookingError => e
#   puts "Booking failed: #{e.message}"
# end
#
# ============================================================================

# ============================================================================
# DESIGN PATTERNS DEMONSTRATED
# ============================================================================
#
# 1. SERVICE OBJECT PATTERN
#    - Business logic separated from models
#    - Event model doesn't know about booking workflow
#    - BookingService orchestrates the process
#
# 2. RAILWAY-ORIENTED PROGRAMMING
#    - Chain of operations (validate -> find -> check -> reserve -> create)
#    - First failure short-circuits the rest
#    - Each step returns Result
#
# 3. DEPENDENCY INJECTION
#    - Repository injected via constructor
#    - Easy to test with mock repository
#    - Loose coupling
#
# 4. COMMAND-QUERY SEPARATION
#    - book/book! are commands (change state, return result)
#    - Future: add queries (get_booking, list_bookings)
#
# 5. EXPLICIT ERROR HANDLING
#    - Both Result and Exception patterns available
#    - Caller chooses based on their needs
#    - Clear error messages
#
# ============================================================================