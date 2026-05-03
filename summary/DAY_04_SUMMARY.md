# Day 4 Summary: Error Handling & Contract Design

## What We Built Today

✅ **Custom Exception Hierarchy** - Specific error types for ticketing system  
✅ **Result Classes** - Success/Failure pattern for expected failures  
✅ **BookingService** - Real business logic with proper error handling  
✅ **Two Error Handling Patterns** - Exceptions AND Results  
✅ **Railway-Oriented Programming** - Chaining operations elegantly

---

## The Problem We Solved

### Before (No Proper Error Handling):

```ruby
def book_tickets(event, seats)
  event.reserve_seats(seats)  # What if this fails?
end

# Caller has no idea what can go wrong
# Errors are silent or cryptic
# No way to handle different failure types
```

### After (With Proper Error Handling):

```ruby
# Result pattern:
result = service.book('RubyConf', 5)
result
  .on_success { |booking| send_confirmation(booking) }
  .on_failure { |error| show_error_to_user(error) }

# Exception pattern:
begin
  booking = service.book!('RubyConf', 5)
rescue EventSoldOutError => e
  show_sold_out_page(e.event_name)
rescue InsufficientSeatsError => e
  show_available_seats(e.available)
end
```

---

## Key Concepts Learned

### 1. **Exception Hierarchy**

```ruby
# Ruby's built-in hierarchy:
Exception
  ├── NoMemoryError (DO NOT CATCH!)
  ├── SystemExit (DO NOT CATCH!)
  └── StandardError ← CATCH THIS!
      ├── ArgumentError
      ├── RuntimeError
      └── ... (safe to catch)

# Our custom hierarchy:
TicketingError < StandardError
  ├── BookingError
  │   ├── EventSoldOutError
  │   ├── InsufficientSeatsError
  │   └── InvalidBookingError
  ├── ValidationError
  │   ├── InvalidNameError
  │   └── InvalidDateError
  └── NotFoundError
      ├── EventNotFoundError
      └── VenueNotFoundError
```

**WHY inherit from StandardError?** It's the right base for application errors. Never rescue `Exception` - it catches system errors!

### 2. **Custom Exceptions with Data**

```ruby
class InsufficientSeatsError < BookingError
  attr_reader :available, :requested

  def initialize(available, requested)
    @available = available
    @requested = requested
    super("Only #{available} seats available, but #{requested} requested")
  end
end

# Usage:
begin
  book_tickets
rescue InsufficientSeatsError => e
  puts "Available: #{e.available}"  # Access error data!
  puts "Requested: #{e.requested}"
end
```

**Benefits:**

- Carry additional context
- Better error messages
- Programmatic error handling
- Self-documenting

### 3. **Result Objects - Success/Failure Pattern**

```ruby
# Instead of exceptions for expected failures:
result = operation_that_might_fail

if result.success?
  value = result.value
  # do something with value
else
  error = result.error
  # handle error
end

# Or with Railway pattern:
result
  .on_success { |value| handle_success(value) }
  .on_failure { |error| handle_failure(error) }
```

**Why Result objects?**

- Exceptions are expensive (stack unwinding)
- Exceptions should be for EXCEPTIONAL cases
- Result objects make success/failure explicit
- Forces caller to handle both cases
- Perfect for expected failures (validation, business rules)

### 4. **Railway-Oriented Programming**

Think of your code as railway tracks:

```
Success track: validate → find → check → reserve → create → Success!
                  ↓         ↓       ↓        ↓        ↓
Failure track:    ========================Failure====Failure
```

Once on failure track, you stay on failure track!

```ruby
def book(event_name, seats)
  validate_inputs(event_name, seats)           # Success or failure
    .flat_map { find_event(event_name) }       # If success, continue
    .flat_map { |e| check_availability(e) }    # If still success, continue
    .flat_map { |e| reserve_seats(e, seats) }  # If still success, continue
    .flat_map { |e| create_booking(e) }        # If still success, final step
end

# If ANY step fails, rest are skipped!
```

**Benefits:**

- Clear flow of operations
- First failure stops the chain
- No deep nesting of if/else
- Composable operations

### 5. **Service Object Pattern**

```ruby
# BAD - Business logic in model:
class Event
  def book_tickets(seats, payment)
    check_availability
    charge_payment(payment)
    send_confirmation
    # Model knows too much!
  end
end

# GOOD - Business logic in service:
class BookingService
  def book(event_name, seats)
    # Orchestrates the workflow
    # Event model stays simple
  end
end
```

**Benefits:**

- Models stay simple (data containers)
- Business logic in one place
- Easy to test complex workflows
- Single Responsibility Principle

---

## Exception vs Result - When to Use Which

### Use EXCEPTIONS When:

```ruby
# System failures:
File.open('missing.txt')  # SystemError
Database.connect          # Connection failed

# Programmer errors:
divide_by_zero
nil.upcase               # NoMethodError

# Crossing boundaries:
library_method_fails     # Let it bubble up
```

**Characteristics:**

- ✓ Truly exceptional conditions
- ✓ Should bubble up multiple levels
- ✓ Recovery not possible at call site
- ✓ Violates assumptions

### Use RESULT Objects When:

```ruby
# Business logic failures:
BookingService.book(event, 1000)  # Sold out
PaymentService.charge(card)       # Declined

# Validation failures:
UserService.create(email: '')     # Invalid

# Expected failures:
EmailService.send(email)          # Bounced
```

**Characteristics:**

- ✓ Expected failures
- ✓ Business rule violations
- ✓ Caller should handle both success/failure
- ✓ Chaining multiple operations

---

## Design Patterns Learned

### 1. **Custom Exception Classes**

```ruby
class EventSoldOutError < BookingError
  attr_reader :event_name

  def initialize(event_name)
    @event_name = event_name
    super("Event '#{event_name}' is sold out")
  end

  def to_h
    { error: 'EventSoldOut', event: event_name }
  end
end
```

**Use for:**

- API error responses
- Logging with context
- Specific error handling
- User-friendly messages

### 2. **Result Monad**

```ruby
class Result
  def self.success(value)
    Success.new(value)
  end

  def self.failure(error)
    Failure.new(error)
  end
end

class Success
  def flat_map
    result = yield(value)
    result.is_a?(Result) ? result : Result.success(result)
  end
end

class Failure
  def flat_map
    self  # Do nothing, stay on failure track
  end
end
```

**Use for:**

- Chaining operations
- Explicit error handling
- Railway-oriented programming
- Composable logic

### 3. **Service Object**

```ruby
class BookingService
  def initialize(repository)
    @repository = repository  # Dependency injection
  end

  def book(event_name, seats)
    # Orchestrate workflow
    # Return Result
  end

  def book!(event_name, seats)
    # Same workflow
    # Raise exceptions
  end
end
```

**Benefits:**

- Separate business logic from models
- Testable (inject mock repository)
- Single Responsibility
- Clear API (book vs book!)

---

## Code Examples

### Exception Hierarchy

```ruby
# Base error
class TicketingError < StandardError
  attr_reader :details

  def initialize(message, details = {})
    super(message)
    @details = details
  end

  def to_h
    {
      error: self.class.name,
      message: message,
      details: details
    }
  end
end

# Specific errors
class EventSoldOutError < TicketingError
  attr_reader :event_name

  def initialize(event_name)
    @event_name = event_name
    super(
      "Event '#{event_name}' is sold out",
      { event: event_name, available_seats: 0 }
    )
  end
end

# Usage:
begin
  book_tickets
rescue EventSoldOutError => e
  puts e.event_name  # Access specific data
  api_response = e.to_h  # Convert to hash for JSON
rescue TicketingError => e
  logger.error(e.details)  # Log with context
end
```

### Result Pattern

```ruby
# Simple usage:
result = service.book('RubyConf', 5)

if result.success?
  booking = result.value
  puts "Booked! ID: #{booking.booking_id}"
else
  puts "Failed: #{result.error}"
end

# Railway pattern:
result
  .on_success { |booking| send_confirmation(booking) }
  .on_failure { |error| log_error(error) }

# Chaining:
def complex_workflow
  validate_user
    .flat_map { |user| check_balance(user) }
    .flat_map { |user| charge_payment(user) }
    .flat_map { |payment| send_receipt(payment) }
end

# Map to transform:
Result.success(10)
  .map { |n| n * 2 }
  .map { |n| n + 5 }
  .value  # => 25

# Get value with default:
booking = result.value_or(default_booking)
```

### BookingService

```ruby
class BookingService
  def book(event_name, requested_seats)
    validate_inputs(event_name, requested_seats)
      .flat_map { find_event(event_name) }
      .flat_map { |e| check_availability(e, requested_seats) }
      .flat_map { |e| reserve_seats(e, requested_seats) }
      .flat_map { |e| create_booking(e, requested_seats) }
  end

  def book!(event_name, requested_seats)
    result = book(event_name, requested_seats)

    result.success? ? result.value : raise(exception_from_error(result.error))
  end

  private

  def validate_inputs(event_name, seats)
    return Result.failure('Event name required') if event_name.empty?
    return Result.failure('Seats must be positive') unless seats.positive?

    Result.success(true)
  end

  def find_event(name)
    event = @repository.find_by_name(name)
    event ? Result.success(event) : Result.failure("Event '#{name}' not found")
  end

  # ... other methods
end
```

---

## Testing Error Handling

### Testing Exceptions

```ruby
RSpec.describe BookingService do
  describe '#book!' do
    it 'raises EventNotFoundError' do
      expect {
        service.book!('NonExistent', 5)
      }.to raise_error(EventNotFoundError, /NonExistent/)
    end

    it 'error includes event name' do
      begin
        service.book!('Missing', 5)
      rescue EventNotFoundError => e
        expect(e.identifier).to eq('Missing')
      end
    end
  end
end
```

### Testing Result Objects

```ruby
describe '#book' do
  it 'returns Success with booking' do
    result = service.book('RubyConf', 5)

    expect(result).to be_success
    expect(result.value).to be_a(Booking)
  end

  it 'returns Failure when sold out' do
    result = service.book('Sold Out Event', 5)

    expect(result).to be_failure
    expect(result.error).to include('sold out')
  end
end
```

---

## Common Patterns Comparison

### Error Handling Strategies

| Strategy        | Use Case                  | Example                                 |
| --------------- | ------------------------- | --------------------------------------- |
| Return nil      | Simple, no context needed | `users.find_by(email: email)`           |
| Raise exception | Exceptional conditions    | `File.open('missing.txt')`              |
| Return Result   | Expected failures         | `BookingService.book(event, 100)`       |
| Status codes    | HTTP, legacy              | `response = { status: 404, body: ... }` |

### Comparison

```ruby
# Nil return:
user = User.find_by(email: email)
if user
  # success
else
  # not found (but why? typo? doesn't exist?)
end

# Exception:
begin
  user = User.find(id)  # Raises if not found
rescue ActiveRecord::RecordNotFound
  # not found
end

# Result:
result = UserService.create(email: email)
result
  .on_success { |user| welcome_email(user) }
  .on_failure { |errors| show_errors(errors) }
```

---

## Best Practices

### 1. **Specific Exceptions**

```ruby
# BAD - Generic exception
raise 'Something went wrong'

# GOOD - Specific exception with data
raise InsufficientSeatsError.new(available, requested)
```

### 2. **Always Rescue StandardError**

```ruby
# BAD - Catches everything (including SystemExit!)
begin
  code
rescue Exception => e
end

# GOOD - Catches application errors only
begin
  code
rescue StandardError => e
end
```

### 3. **Provide Context**

```ruby
# BAD - No context
raise ArgumentError, 'Invalid'

# GOOD - Clear context
raise ArgumentError, "Seats must be between 1 and #{max_seats}, got #{seats}"
```

### 4. **Use ensure for Cleanup**

```ruby
def process_file(path)
  file = File.open(path)
  begin
    # process file
  ensure
    file.close  # Always runs
  end
end
```

### 5. **Don't Rescue Too Broadly**

```ruby
# BAD - Catches too much
begin
  lots_of_code
rescue StandardError
  # Which error? Where?
end

# GOOD - Rescue specific errors
begin
  book_tickets
rescue EventSoldOutError => e
  handle_sold_out
rescue InsufficientSeatsError => e
  handle_insufficient
end
```

---

## Looking Back

### Day 1: Event class with basic validation

### Day 2: EventRepository with querying

### Day 3: Modules for shared behavior

### Day 4: Error handling with BookingService ← YOU ARE HERE

**How they connect:**

```ruby
# Day 1: Create event
event = Event.new(name: 'RubyConf')

# Day 2: Store and query
repo = EventRepository.new([event])

# Day 3: Shared validation
class Event
  include Validatable  # Shared logic
end

# Day 4: Business logic with errors
service = BookingService.new(repo)
result = service.book('RubyConf', 5)  # Proper error handling
```

---

## Looking Ahead to Day 5

Tomorrow: **Value Objects & Form Objects**

**Topics:**

- Money value object (with currency)
- DateRange value object
- Ticket type hierarchy
- Form objects for complex forms
- Avoiding primitive obsession

**We'll build:**

- Money class for pricing
- TicketType hierarchy (VIP, General, Student)
- BookingForm for user input
- Proper value equality

**Then Day 6:** 🧹 **Big Refactoring** - Reorganize project structure!

---

## Exercises to Reinforce Learning

See `DAY_4_EXERCISES.md` for hands-on practice:

1. Add retry logic to BookingService
2. Create PaymentResult with Success/Failure
3. Implement Null Object pattern for GuestUser
4. Add timeout handling
5. Create error notification service

---

## Key Takeaways

1. ✅ **Exceptions for EXCEPTIONAL conditions** - System errors, programmer errors
2. ✅ **Result for EXPECTED failures** - Business logic, validation
3. ✅ **Custom exceptions with data** - Better error messages and handling
4. ✅ **Railway-oriented programming** - Chain operations elegantly
5. ✅ **Service objects for business logic** - Keep models simple
6. ✅ **Both patterns available** - Choose based on needs (book vs book!)
7. ✅ **Always rescue StandardError** - Never rescue Exception

---

## Commands Reference

```bash
# Run error handling tutorial
docker compose run --rm app ruby lib/error_handling_tutorial.rb

# Run booking service demo
docker compose run --rm app ruby day_4_demo.rb

# Run tests
docker compose run --rm app bundle exec rspec

# Run specific test file
docker compose run --rm app bundle exec rspec spec/services/booking_service_spec.rb
docker compose run --rm app bundle exec rspec spec/result_spec.rb
```

---

**Great work on Day 4! 🎉**

You now have a solid foundation in error handling - both exceptions and Result objects. This is critical for building robust production systems!

**Ready for Day 5?** Let me know!
