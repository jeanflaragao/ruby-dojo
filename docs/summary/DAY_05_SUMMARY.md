# DAY 5: VALUE OBJECTS & FORM OBJECTS

## Overview

Today we tackled **primitive obsession** - a code smell where we use basic types (integers, strings) instead of proper domain objects. We built value objects and form objects to make our code more expressive, safer, and maintainable.

## What Are Value Objects?

**Value objects** are small, immutable objects that:

- Represent a conceptual whole (like Money = amount + currency)
- Are equal based on their VALUES, not their identity
- Are frozen/immutable after creation
- Have no setters, only readers
- Methods return new instances instead of modifying

### Why Value Objects?

**Primitive Obsession** is when you use basic types everywhere:

```ruby
# ❌ PRIMITIVE OBSESSION
price = 100                    # What currency? Can go negative? Can add to EUR?
start_date = Date.new(2024, 1, 1)
end_date = Date.new(2024, 1, 31)
# ^ Two separate dates with no relationship

# ✅ VALUE OBJECTS
price = Money.new(100, 'USD')  # Clear, safe, domain-specific
dates = DateRange.new(start_date, end_date)  # Encapsulates relationship
```

**Benefits:**

1. **Type Safety** - Can't accidentally add USD to EUR
2. **Domain Rules** - Money enforces positive amounts
3. **Expressiveness** - `dates.overlaps?(other)` vs manual date comparison
4. **Immutability** - No accidental modification
5. **Reusability** - Same logic in one place

---

## 1. Money Value Object

### Core Concept

Money is NOT just a number - it's amount + currency with domain rules.

### Implementation

```ruby
class Money
  attr_reader :amount, :currency

  def initialize(amount, currency = 'USD')
    raise ArgumentError, 'Amount must be positive' unless amount.positive?
    @amount = amount
    @currency = currency
    freeze  # Immutable!
  end

  # Value equality, not identity
  def ==(other)
    amount == other.amount && currency == other.currency
  end

  # Arithmetic returns NEW instances
  def +(other)
    ensure_same_currency!(other)
    Money.new(amount + other.amount, currency)
  end

  def *(multiplier)
    Money.new(amount * multiplier, currency)
  end
end
```

### Key Features

**Immutability:**

```ruby
price = Money.new(100, 'USD')
price.frozen?  # => true
# price.amount = 200  # ❌ NoMethodError - no setter!
```

**Value Equality:**

```ruby
m1 = Money.new(100, 'USD')
m2 = Money.new(100, 'USD')
m1 == m2         # => true (same value)
m1.equal?(m2)    # => false (different objects)
```

**Currency Safety:**

```ruby
usd = Money.new(100, 'USD')
eur = Money.new(100, 'EUR')
usd + eur  # => ArgumentError: Currency mismatch
```

**Hash Keys:**

```ruby
prices = {
  Money.new(10, 'USD') => 'coffee',
  Money.new(50, 'USD') => 'ticket'
}
prices[Money.new(10, 'USD')]  # => 'coffee' (works because of value equality)
```

---

## 2. DateRange Value Object

### Core Concept

A date range is more than two dates - it's a conceptual whole with domain operations.

### Implementation

```ruby
class DateRange
  attr_reader :start_date, :end_date

  def initialize(start_date, end_date)
    raise ArgumentError if start_date > end_date
    @start_date = start_date
    @end_date = end_date
    freeze
  end

  def days
    (end_date - start_date).to_i + 1  # Inclusive
  end

  def includes?(date)
    date >= start_date && date <= end_date
  end

  def overlaps?(other)
    start_date <= other.end_date && end_date >= other.start_date
  end
end
```

### Usage Examples

**Event Scheduling:**

```ruby
conference = DateRange.new(Date.new(2024, 6, 1), Date.new(2024, 6, 3))
workshop = DateRange.new(Date.new(2024, 6, 3), Date.new(2024, 6, 5))

conference.overlaps?(workshop)  # => true (touch on June 3)
conference.days                 # => 3
```

**Availability Checking:**

```ruby
booking_period = DateRange.new(Date.today, Date.today + 7)
check_in = Date.today + 3

booking_period.includes?(check_in)  # => true
```

---

## 3. TicketType Hierarchy

### Core Concept

Different ticket types share interface but differ in pricing/perks - this is an ACCEPTABLE use of inheritance for value objects.

### Design Pattern: Template Method

```ruby
class TicketType
  def price
    base_price * price_multiplier  # Template method
  end

  # Subclasses override these
  def price_multiplier
    raise NotImplementedError
  end

  def perks
    raise NotImplementedError
  end
end

class VIPTicket < TicketType
  def price_multiplier; 2.0; end
  def perks; ['Priority seating', 'Meet & greet']; end
end

class StudentTicket < TicketType
  def price_multiplier; 0.7; end  # 30% discount
  def perks; ['Student discount']; end
  def requires_verification?; true; end
end
```

### Polymorphism in Action

```ruby
base = Money.new(100, 'USD')
tickets = [
  VIPTicket.new(base),
  GeneralTicket.new(base),
  StudentTicket.new(base)
]

# Same interface, different behavior
tickets.each do |ticket|
  puts "#{ticket.tier}: #{ticket.price}"
end
# => VIP: 200.00 USD
# => General: 100.00 USD
# => Student: 70.00 USD
```

### When Inheritance is OK

✅ **Good use** (Value object hierarchies):

- TicketType - natural type hierarchy
- All share same interface
- Differs only in data/behavior

❌ **Bad use** (Business logic):

- UserService < BaseService
- DeepHierarchy > ChainOfInheritance
- Use composition instead!

---

## 4. Form Objects

### Core Concept

Form objects separate **input validation** from **business logic**.

**Problem:**

```ruby
# ❌ Business logic handles raw input
BookingService.book(params[:event_name], params[:seats])
# What if seats = "abc"? What if event_name is nil?
```

**Solution:**

```ruby
# ✅ Form validates/coerces FIRST
form = BookingForm.new(params)
if form.valid?
  BookingService.book(form.to_h)  # Clean, coerced data
else
  render json: { errors: form.error_messages }
end
```

### Implementation

```ruby
class BookingForm
  VALID_TICKET_TYPES = %w[vip general student]
  MAX_SEATS = 10

  attr_reader :event_name, :seats, :ticket_type, :email, :errors

  def initialize(params = {})
    @event_name = params[:event_name]
    @seats = params[:seats]  # Still a string!
    @ticket_type = params[:ticket_type]
    @email = params[:email]
    @errors = {}
  end

  def valid?
    @errors = {}
    validate_event_name
    validate_seats
    validate_ticket_type
    validate_email
    @errors.empty?
  end

  def to_h
    {
      event_name: event_name,
      seats: seats.to_i,              # Coerce to integer
      ticket_type: ticket_type.to_sym, # Coerce to symbol
      email: email
    }
  end

  private

  def validate_seats
    if blank?(seats)
      add_error(:seats, "can't be blank")
    elsif !numeric?(seats)
      add_error(:seats, 'must be a number')
    elsif seats.to_i <= 0
      add_error(:seats, 'must be positive')
    elsif seats.to_i > MAX_SEATS
      add_error(:seats, "cannot exceed #{MAX_SEATS}")
    end
  end
end
```

### Benefits

1. **Type Safety** - Converts "3" → 3, "vip" → :vip
2. **Early Validation** - Catch bad input before business logic
3. **Clear Errors** - User-friendly messages
4. **Separation** - Form concerns separate from domain logic
5. **Testability** - Easy to test validation rules

### Example Usage

```ruby
# Invalid form
form = BookingForm.new(seats: 'abc', email: 'bad')
form.valid?  # => false
form.errors  # => { seats: ['must be a number'], email: ['must be valid'] }
form.error_messages  # => ["Seats must be a number", "Email must be valid"]

# Valid form
form = BookingForm.new(
  event_name: 'Conference',
  seats: '3',
  ticket_type: 'vip',
  email: 'user@example.com'
)
form.valid?  # => true
form.to_h    # => { event_name: "Conference", seats: 3, ticket_type: :vip, ... }
```

---

## Comparing Value Objects vs Form Objects

| Aspect           | Value Objects      | Form Objects              |
| ---------------- | ------------------ | ------------------------- |
| **Purpose**      | Domain concepts    | Input validation          |
| **Immutability** | Always frozen      | Mutable during validation |
| **Equality**     | By value           | By identity               |
| **Usage**        | Throughout domain  | Controller/API layer      |
| **Examples**     | Money, DateRange   | BookingForm, SignupForm   |
| **Persistence**  | Not saved directly | Never saved               |

---

## Integration Example

Here's how all pieces work together:

```ruby
# 1. Form validates raw input
form = BookingForm.new(params)

if form.valid?
  # 2. Get clean, coerced data
  booking_data = form.to_h

  # 3. Business service uses value objects
  ticket = VIPTicket.new(Money.new(100, 'USD'))
  total_price = ticket.price * booking_data[:seats]

  # 4. Create booking
  booking = BookingService.book(
    booking_data[:event_name],
    booking_data[:seats],
    ticket
  )

  render json: { total: total_price.to_h }
else
  render json: { errors: form.error_messages }, status: 422
end
```

---

## Testing Value Objects

### Money Tests

```ruby
RSpec.describe Money do
  it 'is immutable' do
    money = Money.new(100, 'USD')
    expect(money).to be_frozen
  end

  it 'has value equality' do
    expect(Money.new(100, 'USD')).to eq(Money.new(100, 'USD'))
  end

  it 'prevents currency mismatch' do
    expect { Money.new(100, 'USD') + Money.new(100, 'EUR') }
      .to raise_error(ArgumentError, /mismatch/)
  end
end
```

### Form Object Tests

```ruby
RSpec.describe BookingForm do
  it 'validates presence of event_name' do
    form = BookingForm.new(event_name: '')
    expect(form).not_to be_valid
    expect(form.errors[:event_name]).to include("can't be blank")
  end

  it 'coerces seats to integer' do
    form = BookingForm.new(seats: '5')
    expect(form.to_h[:seats]).to eq(5)
    expect(form.to_h[:seats]).to be_a(Integer)
  end
end
```

---

## Common Patterns & Best Practices

### 1. Always Freeze Value Objects

```ruby
def initialize(amount, currency)
  @amount = amount
  @currency = currency
  freeze  # ✅ Make immutable
end
```

### 2. Implement Hash/Equality for Collections

```ruby
def ==(other)
  amount == other.amount && currency == other.currency
end

alias eql? ==

def hash
  [amount, currency].hash
end
```

### 3. Return New Instances from Operations

```ruby
# ❌ Mutation
def add(other)
  @amount += other.amount  # BAD!
end

# ✅ New instance
def +(other)
  Money.new(amount + other.amount, currency)
end
```

### 4. Form Objects Should Coerce Types

```ruby
def to_h
  {
    seats: seats.to_i,              # String → Integer
    ticket_type: ticket_type.to_sym, # String → Symbol
    confirmed: confirmed == 'true'   # String → Boolean
  }
end
```

### 5. Keep Business Logic OUT of Forms

```ruby
# ❌ Business logic in form
class BookingForm
  def process_booking
    BookingService.book(...)  # NO!
  end
end

# ✅ Form only validates
class BookingForm
  def valid?; end
  def to_h; end  # That's it!
end
```

---

## Files Created Today

```
lib/value_objects/
  ├── money.rb           # Money value object
  └── date_range.rb      # DateRange value object

lib/models/
  └── ticket_type.rb     # TicketType hierarchy (VIP/General/Student)

lib/forms/
  └── booking_form.rb    # Form object for booking validation

spec/value_objects/
  ├── money_spec.rb      # Money tests
  └── date_range_spec.rb # DateRange tests

spec/models/
  └── ticket_type_spec.rb # TicketType tests

spec/forms/
  └── booking_form_spec.rb # BookingForm tests

day_5_demo.rb            # Comprehensive demonstration
```

---

## Next Steps

**Tomorrow (Day 6 Morning)**: BIG REFACTORING!

- Clean up project structure
- Remove duplicate Event/Venue classes
- Organize tutorials into separate folder
- Create proper directory hierarchy
- Update all requires

**Tomorrow (Day 6 Afternoon)**: Continue with clean codebase!

---

## Key Takeaways

1. **Value Objects prevent primitive obsession**
   - Money instead of raw integers
   - DateRange instead of two separate dates
   - Domain rules encapsulated

2. **Value Objects are IMMUTABLE**
   - Frozen after creation
   - Methods return new instances
   - Safe to use as hash keys

3. **Equality by value, not identity**
   - `Money.new(100, 'USD') == Money.new(100, 'USD')` → true
   - Same values = equal, even if different objects

4. **Form Objects separate concerns**
   - Validate raw user input
   - Coerce types (strings → integers/symbols)
   - Keep business logic clean

5. **Inheritance is OK for value types**
   - TicketType hierarchy makes sense
   - All tickets share interface
   - Different behavior through polymorphism
   - NOT for business logic!

**Tomorrow we refactor the entire project structure, then continue building!** 🎓
