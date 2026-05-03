# frozen_string_literal: true

# Error Handling Tutorial - Day 4
# Run: docker compose run --rm app ruby lib/error_handling_tutorial.rb

puts "=" * 70
puts "Error Handling in Ruby - From Basics to Advanced Patterns"
puts "=" * 70
puts

# ============================================================================
# PART 1: Exception Basics
# ============================================================================

puts "1. EXCEPTION BASICS - raise and rescue"
puts "-" * 70

# Raising exceptions
def divide(a, b)
  raise ArgumentError, 'Divisor cannot be zero' if b.zero?

  a / b
end

puts "Dividing 10 by 2:"
result = divide(10, 2)
puts "  Result: #{result}"
puts

puts "Dividing 10 by 0:"
begin
  divide(10, 0)
rescue ArgumentError => e
  puts "  ✓ Caught error: #{e.message}"
end
puts

# WHY use exceptions? Signal that something went wrong and cannot continue
# WHEN NOT to use: For normal flow control (use Result objects instead)

# ============================================================================
# PART 2: Exception Hierarchy
# ============================================================================

puts "\n2. EXCEPTION HIERARCHY - StandardError vs Exception"
puts "-" * 70

# Ruby's exception hierarchy:
#   Exception
#     ├── NoMemoryError (DO NOT rescue these!)
#     ├── ScriptError
#     ├── SecurityError
#     ├── SignalException
#     ├── SystemExit
#     └── StandardError (RESCUE THESE!)
#         ├── ArgumentError
#         ├── RuntimeError
#         ├── TypeError
#         └── ... (and many more)

puts "Rule: ALWAYS rescue StandardError or its subclasses"
puts "      NEVER rescue Exception (catches system errors!)"
puts

# BAD - Don't do this!
# begin
#   # code
# rescue Exception => e  # ← WRONG! Catches everything including system errors
# end

# GOOD - Do this:
# begin
#   # code
# rescue StandardError => e  # ← CORRECT! Only application errors
# end

# Or even better, rescue specific errors:
# begin
#   # code
# rescue ArgumentError, TypeError => e
# end

# ============================================================================
# PART 3: Custom Exception Classes
# ============================================================================

puts "\n3. CUSTOM EXCEPTION CLASSES - Make errors meaningful"
puts "-" * 70

# Define custom exceptions
class BookingError < StandardError; end

class TicketSoldOutError < BookingError
  attr_reader :event_name, :requested_seats

  def initialize(event_name, requested_seats)
    @event_name = event_name
    @requested_seats = requested_seats
    super("Event '#{event_name}' is sold out. Cannot book #{requested_seats} seats.")
  end
end

class InsufficientSeatsError < BookingError
  attr_reader :available, :requested

  def initialize(available, requested)
    @available = available
    @requested = requested
    super("Only #{available} seats available, but #{requested} requested.")
  end
end

# Using custom exceptions
def book_tickets(event_name, available_seats, requested_seats)
  if available_seats.zero?
    raise TicketSoldOutError.new(event_name, requested_seats)
  elsif requested_seats > available_seats
    raise InsufficientSeatsError.new(available_seats, requested_seats)
  end

  "Booked #{requested_seats} seats for #{event_name}"
end

puts "Booking 5 seats (10 available):"
begin
  result = book_tickets('RubyConf', 10, 5)
  puts "  ✓ #{result}"
rescue BookingError => e
  puts "  ✗ #{e.message}"
end
puts

puts "Booking 15 seats (10 available):"
begin
  book_tickets('RubyConf', 10, 15)
rescue InsufficientSeatsError => e
  puts "  ✗ #{e.message}"
  puts "  Available: #{e.available}"
  puts "  Requested: #{e.requested}"
end
puts

puts "Booking when sold out:"
begin
  book_tickets('RubyConf', 0, 5)
rescue TicketSoldOutError => e
  puts "  ✗ #{e.message}"
  puts "  Event: #{e.event_name}"
end
puts

# WHY custom exceptions?
# - More specific error handling
# - Can carry additional data (available, requested, etc.)
# - Self-documenting code
# - Better error messages for users

# ============================================================================
# PART 4: Result Objects (Alternative to Exceptions)
# ============================================================================

puts "\n4. RESULT OBJECTS - Railway-Oriented Programming"
puts "-" * 70

# Problem: Exceptions are expensive and should be for EXCEPTIONAL cases
# Solution: Use Result objects for expected failures

class Result
  def self.success(value)
    Success.new(value)
  end

  def self.failure(error)
    Failure.new(error)
  end

  def success?
    false
  end

  def failure?
    false
  end
end

class Success < Result
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def success?
    true
  end

  def on_success
    yield(value) if block_given?
    self
  end

  def on_failure
    self
  end
end

class Failure < Result
  attr_reader :error

  def initialize(error)
    @error = error
  end

  def failure?
    true
  end

  def on_success
    self
  end

  def on_failure
    yield(error) if block_given?
    self
  end
end

# Using Result objects
def book_with_result(available, requested)
  if requested > available
    Result.failure("Not enough seats: #{available} available, #{requested} requested")
  else
    Result.success({ available: available - requested, booked: requested })
  end
end

puts "Result pattern - successful booking:"
result = book_with_result(10, 5)
result
  .on_success { |data| puts "  ✓ Booked #{data[:booked]} seats, #{data[:available]} remaining" }
  .on_failure { |error| puts "  ✗ Failed: #{error}" }
puts

puts "Result pattern - failed booking:"
result = book_with_result(10, 15)
result
  .on_success { |data| puts "  ✓ Booked #{data[:booked]} seats" }
  .on_failure { |error| puts "  ✗ Failed: #{error}" }
puts

# WHY Result objects?
# - Exceptions are for exceptional cases
# - Result objects are for expected failures
# - Forces explicit error handling
# - Easier to test
# - Railway-oriented programming pattern

# ============================================================================
# PART 5: ensure and retry
# ============================================================================

puts "\n5. ENSURE AND RETRY - Cleanup and retries"
puts "-" * 70

# ensure - ALWAYS executes (like finally in other languages)
def with_resource
  puts "  Opening resource..."
  begin
    puts "  Using resource..."
    # simulate work
  ensure
    puts "  Closing resource (always runs!)"
  end
end

puts "Using ensure:"
with_resource
puts

# retry - Retry the begin block
def flaky_operation(attempt = 1)
  puts "  Attempt #{attempt}..."
  raise 'Network error' if attempt < 3

  'Success!'
end

def call_flaky_service
  attempt = 0
  begin
    attempt += 1
    result = flaky_operation(attempt)
    puts "  ✓ #{result}"
  rescue StandardError => e
    if attempt < 3
      puts "  ✗ Failed: #{e.message}, retrying..."
      retry  # Goes back to begin
    else
      puts "  ✗ Failed after 3 attempts: #{e.message}"
    end
  end
end

puts "Using retry:"
call_flaky_service
puts

# ============================================================================
# PART 6: Exception vs Result - When to use which?
# ============================================================================

puts "\n6. EXCEPTION vs RESULT - Decision Guide"
puts "-" * 70

puts "USE EXCEPTIONS WHEN:"
puts "  ✓ Truly exceptional conditions (out of memory, file not found)"
puts "  ✓ Programmer errors (wrong arguments, nil reference)"
puts "  ✓ System failures (network timeout, database down)"
puts "  ✓ Crossing abstraction boundaries (library code)"
puts

puts "USE RESULT OBJECTS WHEN:"
puts "  ✓ Expected failures (validation errors, business rules)"
puts "  ✓ User input errors (invalid email, weak password)"
puts "  ✓ Business logic failures (insufficient funds, sold out)"
puts "  ✓ Flow control with multiple possible outcomes"
puts

puts "EXAMPLE MAPPING:"
puts "  Exception: File.open('nonexistent.txt')  # SystemError"
puts "  Result:    BookingService.book(event, 1000)  # Expected failure"
puts

# ============================================================================
# PART 7: Null Object Pattern
# ============================================================================

puts "\n7. NULL OBJECT PATTERN - Avoiding nil checks"
puts "-" * 70

# Problem: nil checks everywhere
class User
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def admin?
    false
  end
end

# Without Null Object
def greet_without_null_object(user)
  if user.nil?
    "Hello, Guest"
  else
    "Hello, #{user.name}"
  end
end

# With Null Object
class GuestUser
  def name
    'Guest'
  end

  def admin?
    false
  end

  def nil?
    false  # Not actually nil, but represents absence
  end
end

def greet_with_null_object(user)
  "Hello, #{user.name}"
end

puts "Without Null Object:"
puts "  #{greet_without_null_object(nil)}"
puts "  #{greet_without_null_object(User.new('Alice'))}"
puts

puts "With Null Object:"
puts "  #{greet_with_null_object(GuestUser.new)}"
puts "  #{greet_with_null_object(User.new('Alice'))}"
puts

# WHY Null Object?
# - No nil checks needed
# - Polymorphic behavior
# - Follows "Tell, Don't Ask" principle

# ============================================================================
# SUMMARY
# ============================================================================

puts "=" * 70
puts "KEY TAKEAWAYS"
puts "=" * 70
puts
puts "1. Use exceptions for EXCEPTIONAL conditions"
puts "2. Use Result objects for EXPECTED failures"
puts "3. Always rescue StandardError, not Exception"
puts "4. Create custom exceptions with meaningful data"
puts "5. Use ensure for cleanup (like finally)"
puts "6. Use retry for transient failures"
puts "7. Use Null Object to avoid nil checks"
puts
puts "NEXT: We'll build BookingService with proper error handling!"
puts "=" * 70