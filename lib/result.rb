# frozen_string_literal: true

# Result - Railway-Oriented Programming Pattern
#
# WHY? Not all failures are exceptional. Sometimes failure is expected
# (validation fails, business rule violated, resource unavailable).
#
# PROBLEM WITH EXCEPTIONS:
# - Expensive (stack unwinding)
# - Implicit (caller might not know method can fail)
# - Break normal flow
#
# SOLUTION - RESULT OBJECTS:
# - Explicit success/failure in return type
# - Forces callers to handle both cases
# - Cheap (just objects, no stack unwinding)
# - Composable (chain operations)
#
# USAGE:
#   result = BookingService.book(event, seats)
#
#   if result.success?
#     puts "Booked! Confirmation: #{result.value}"
#   else
#     puts "Failed: #{result.error}"
#   end
#
#   # Or with blocks (Railway pattern):
#   result
#     .on_success { |booking| send_confirmation(booking) }
#     .on_failure { |error| log_error(error) }

# Base Result class
# WHY abstract class? Ensures you use Success or Failure, never Result directly
class Result
  # Factory methods for creating results
  def self.success(value = nil)
    Success.new(value)
  end

  def self.failure(error)
    Failure.new(error)
  end

  # Type checking methods
  def success?
    false
  end

  def failure?
    false
  end

  # These must be implemented by subclasses
  def value
    raise NotImplementedError, 'Subclass must implement value or error'
  end

  def error
    raise NotImplementedError, 'Subclass must implement value or error'
  end
end

# Success - represents a successful operation
class Success < Result
  attr_reader :value

  def initialize(value = nil)
    @value = value
  end

  def success?
    true
  end

  # Railway pattern - execute block on success
  # WHY return self? Allows chaining
  def on_success
    yield(value) if block_given?
    self
  end

  # Railway pattern - skip block on success
  def on_failure
    self
  end

  # Map the value to a new value
  # WHY useful? Transform success values without unwrapping
  def map
    return self unless block_given?

    Result.success(yield(value))
  end

  # Flat map - when block returns another Result
  # WHY needed? Avoid Result<Result<T>>
  def flat_map
    return self unless block_given?

    result = yield(value)
    result.is_a?(Result) ? result : Result.success(result)
  end

  # Get value or default
  def value_or(_default)
    value
  end

  def to_s
    "Success(#{value.inspect})"
  end
end

# Failure - represents a failed operation
class Failure < Result
  attr_reader :error

  def initialize(error)
    @error = error
  end

  def failure?
    true
  end

  # Railway pattern - skip block on failure
  def on_success
    self
  end

  # Railway pattern - execute block on failure
  def on_failure
    yield(error) if block_given?
    self
  end

  # Map - do nothing on failure
  def map
    self
  end

  # Flat map - do nothing on failure
  def flat_map
    self
  end

  # Get value or default
  def value_or(default)
    default
  end

  def to_s
    "Failure(#{error.inspect})"
  end
end

# ============================================================================
# USAGE EXAMPLES
# ============================================================================
#
# # Simple success/failure:
# result = Result.success({ booking_id: 123, seats: 5 })
# result.success?  # => true
# result.value     # => { booking_id: 123, seats: 5 }
#
# result = Result.failure('Not enough seats')
# result.failure?  # => true
# result.error     # => 'Not enough seats'
#
# # With blocks (Railway pattern):
# Result.success(booking)
#   .on_success { |b| send_email(b.customer_email) }
#   .on_failure { |error| log_error(error) }
#
# # Chaining operations:
# def book_ticket(event, seats)
#   validate_seats(event, seats)
#     .flat_map { |_| reserve_seats(event, seats) }
#     .flat_map { |booking| charge_payment(booking) }
#     .flat_map { |booking| send_confirmation(booking) }
# end
#
# # Map to transform success values:
# Result.success(10)
#   .map { |n| n * 2 }
#   .map { |n| n + 5 }
#   .value  # => 25
#
# # Get value with default:
# result.value_or(default_booking)
#
# ============================================================================

# ============================================================================
# WHEN TO USE RESULT VS EXCEPTION
# ============================================================================
#
# USE RESULT WHEN:
# ✓ Failure is EXPECTED (validation, business rules)
# ✓ Caller should always handle both success/failure
# ✓ You want explicit error handling
# ✓ You're chaining multiple operations
#
# USE EXCEPTION WHEN:
# ✓ Failure is EXCEPTIONAL (system error, programmer error)
# ✓ Error should bubble up multiple levels
# ✓ Recovery is not possible at call site
# ✓ Violates fundamental assumptions (nil when not allowed)
#
# EXAMPLES:
#
# Result:
#   - Validating user input
#   - Checking business rules (sufficient balance, available seats)
#   - Optional operations (find user by email)
#
# Exception:
#   - Database connection failed
#   - File system error
#   - Nil argument when nil is not allowed
#   - Type mismatch
#
# ============================================================================

# ============================================================================
# RAILWAY-ORIENTED PROGRAMMING
# ============================================================================
#
# Think of your code as a railway track:
#
#   Success track: ═══════════════════════════════> Success!
#                      ↓ (any failure)
#   Failure track: ════════════════════════════════> Failure
#
# Each operation either:
# - Succeeds and stays on success track
# - Fails and switches to failure track (and stays there)
#
# Example:
#
#   validate(input)           # Success or switch to failure
#     ↓
#   reserve_seats(event)      # Success or failure (stays on failure)
#     ↓
#   charge_payment(booking)   # Success or failure (stays on failure)
#     ↓
#   send_confirmation(booking) # Success or failure (stays on failure)
#
# Once on failure track, all subsequent operations are skipped!
#
# ============================================================================
