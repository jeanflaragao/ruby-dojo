#!/usr/bin/env ruby
# frozen_string_literal: true

# Day 4 Demo - Error Handling & BookingService
# Run: docker compose run --rm app ruby day_4_demo.rb

require_relative 'lib/event'
require_relative 'lib/venue'
require_relative 'lib/event_repository'
require_relative 'lib/services/booking_service'
require_relative 'lib/errors/ticketing_errors'
require_relative 'lib/result'

puts "=" * 80
puts "Day 4: Error Handling & BookingService Demonstration"
puts "=" * 80
puts

# ============================================================================
# SETUP: Create events and repository
# ============================================================================

puts "Setting up test data..."
puts "-" * 80

venue = Venue.new(
  name: 'San Francisco Convention Center',
  address: '123 Main St, SF, CA',
  capacity: 500
)

events = [
  Event.new(
    name: 'RubyConf 2026',
    description: 'Annual Ruby conference',
    venue: venue,
    start_time: Time.new(2026, 6, 15, 9, 0, 0),
    end_time: Time.new(2026, 6, 17, 18, 0, 0),
    total_seats: 100
  ),
  Event.new(
    name: 'Rails Workshop',
    description: 'Hands-on Rails training',
    venue: venue,
    start_time: Time.new(2026, 7, 10, 9, 0, 0),
    end_time: Time.new(2026, 7, 10, 17, 0, 0),
    total_seats: 30
  )
]

# Create one with limited seats
limited_event = Event.new(
  name: 'Exclusive Meetup',
  description: 'Small group meetup',
  venue: venue,
  start_time: Time.new(2026, 8, 5, 18, 0, 0),
  end_time: Time.new(2026, 8, 5, 20, 0, 0),
  total_seats: 10
)
limited_event.reserve_seats(8)  # Only 2 seats left
events << limited_event

repository = EventRepository.new(events)
service = BookingService.new(repository)

puts "✓ Created #{events.size} events"
puts
puts "Available events:"
events.each do |e|
  puts "  - #{e.name}: #{e.available_seats}/#{e.total_seats} seats"
end
puts

# ============================================================================
# PART 1: Result Pattern (Recommended approach)
# ============================================================================

puts "=" * 80
puts "PART 1: RESULT PATTERN - Expected Failures"
puts "=" * 80
puts

puts "1. Successful booking:"
puts "-" * 80
result = service.book('RubyConf 2026', 5)

result
  .on_success do |booking|
    puts "✓ Booking successful!"
    puts "  Booking ID: #{booking.booking_id}"
    puts "  Event: #{booking.event.name}"
    puts "  Seats: #{booking.seats_reserved}"
    puts "  Price: $#{booking.total_price}"
    puts "  Remaining seats: #{booking.event.available_seats}"
  end
  .on_failure do |error|
    puts "✗ Booking failed: #{error}"
  end
puts

puts "2. Event not found:"
puts "-" * 80
result = service.book('NonExistent Event', 5)

if result.success?
  puts "✓ Booked!"
else
  puts "✗ Failed: #{result.error}"
end
puts

puts "3. Insufficient seats:"
puts "-" * 80
result = service.book('Exclusive Meetup', 5)  # Only 2 available

result
  .on_success { |booking| puts "✓ Booked #{booking.seats_reserved} seats" }
  .on_failure { |error| puts "✗ Failed: #{error}" }
puts

puts "4. Invalid input (zero seats):"
puts "-" * 80
result = service.book('RubyConf 2026', 0)

if result.failure?
  puts "✗ Failed: #{result.error}"
end
puts

puts "5. Sold out event:"
puts "-" * 80
# First, book remaining seats
service.book('Exclusive Meetup', 2)  # Book the last 2 seats

result = service.book('Exclusive Meetup', 1)  # Try to book when sold out

result
  .on_success { |_| puts "✓ Somehow booked!" }
  .on_failure { |error| puts "✗ Failed: #{error}" }
puts

# ============================================================================
# PART 2: Exception Pattern (Alternative approach)
# ============================================================================

puts "=" * 80
puts "PART 2: EXCEPTION PATTERN - For Error Bubbling"
puts "=" * 80
puts

puts "1. Successful booking with exceptions:"
puts "-" * 80
begin
  booking = service.book!('Rails Workshop', 5)
  puts "✓ Booking successful!"
  puts "  ID: #{booking.booking_id}"
  puts "  Seats: #{booking.seats_reserved}"
rescue BookingError => e
  puts "✗ Failed: #{e.message}"
end
puts

puts "2. EventNotFoundError:"
puts "-" * 80
begin
  service.book!('Missing Event', 5)
rescue EventNotFoundError => e
  puts "✗ Caught EventNotFoundError"
  puts "  Message: #{e.message}"
  puts "  Resource: #{e.resource_type}"
  puts "  Identifier: #{e.identifier}"
end
puts

puts "3. InsufficientSeatsError:"
puts "-" * 80
begin
  service.book!('Rails Workshop', 50)  # More than available
rescue InsufficientSeatsError => e
  puts "✗ Caught InsufficientSeatsError"
  puts "  Message: #{e.message}"
  puts "  Available: #{e.available}"
  puts "  Requested: #{e.requested}"
  puts "  Suggestion: Try booking #{e.available} seats instead"
end
puts

puts "4. Catching hierarchy of errors:"
puts "-" * 80
begin
  service.book!('NonExistent', 10)
rescue BookingError => e
  # This catches ANY booking error (EventSoldOut, InsufficientSeats, etc.)
  puts "✗ Caught a BookingError (actually #{e.class.name})"
  puts "  Message: #{e.message}"
rescue TicketingError => e
  # This would catch ANY ticketing error (Validation, NotFound, etc.)
  puts "✗ Caught a TicketingError"
end
puts

# ============================================================================
# PART 3: Railway-Oriented Programming
# ============================================================================

puts "=" * 80
puts "PART 3: RAILWAY-ORIENTED PROGRAMMING"
puts "=" * 80
puts

puts "Success path (stays on success track):"
puts "-" * 80
puts "  1. Validate inputs ✓"
puts "  2. Find event ✓"
puts "  3. Check availability ✓"
puts "  4. Reserve seats ✓"
puts "  5. Create booking ✓"
puts

result = service.book('RubyConf 2026', 3)
puts "Result: #{result.success? ? 'Success' : 'Failure'}"
puts

puts "Failure path (switches to failure track):"
puts "-" * 80
puts "  1. Validate inputs ✓"
puts "  2. Find event ✗ (switches to failure track)"
puts "  3. Check availability (skipped)"
puts "  4. Reserve seats (skipped)"
puts "  5. Create booking (skipped)"
puts

result = service.book('Missing Event', 3)
puts "Result: Failure"
puts "Error: #{result.error}"
puts

# ============================================================================
# PART 4: Comparing Approaches
# ============================================================================

puts "=" * 80
puts "PART 4: WHEN TO USE WHICH APPROACH"
puts "=" * 80
puts

puts "USE RESULT PATTERN WHEN:"
puts "  ✓ Failure is EXPECTED (validation, business rules)"
puts "  ✓ You want explicit error handling"
puts "  ✓ Chaining multiple operations"
puts "  ✓ Caller should always handle both success/failure"
puts

puts "USE EXCEPTION PATTERN WHEN:"
puts "  ✓ Failure is EXCEPTIONAL (system error)"
puts "  ✓ You want errors to bubble up automatically"
puts "  ✓ Integrating with existing exception-based code"
puts "  ✓ Recovery is not possible at call site"
puts

puts "BOTH PATTERNS AVAILABLE IN BookingService:"
puts "  • service.book(...) → Returns Result"
puts "  • service.book!(...) → Raises exceptions"
puts

# ============================================================================
# PART 5: Error Data Structures
# ============================================================================

puts "=" * 80
puts "PART 5: ERROR DATA STRUCTURES"
puts "=" * 80
puts

puts "Exceptions carry additional data:"
puts "-" * 80
begin
  service.book!('RubyConf 2026', 200)
rescue InsufficientSeatsError => e
  puts "Error class: #{e.class.name}"
  puts "Available: #{e.available}"
  puts "Requested: #{e.requested}"
  puts "Details hash: #{e.details.inspect}"
  puts "to_h: #{e.to_h.inspect}"
end
puts

# ============================================================================
# SUMMARY
# ============================================================================

puts "=" * 80
puts "KEY TAKEAWAYS"
puts "=" * 80
puts
puts "1. Use Result for EXPECTED failures (business logic)"
puts "2. Use Exceptions for EXCEPTIONAL failures (system errors)"
puts "3. Custom exceptions provide meaningful error data"
puts "4. Railway-oriented programming enables elegant chaining"
puts "5. Service objects separate business logic from models"
puts "6. Both patterns have their place - choose appropriately"
puts
puts "=" * 80

# Final stats
puts "\nFinal seat availability:"
events.each do |e|
  puts "  - #{e.name}: #{e.available_seats}/#{e.total_seats} seats"
end