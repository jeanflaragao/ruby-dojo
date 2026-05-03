# DAY 5 EXERCISES: VALUE OBJECTS & FORM OBJECTS

Complete these exercises to reinforce your understanding of value objects and form objects. Remember: TDD! Write tests first, then implement.

---

## Exercise 1: Address Value Object ⭐

Create an `Address` value object that represents a physical address.

### Requirements

```ruby
# spec/value_objects/address_spec.rb
RSpec.describe Address do
  describe 'initialization' do
    it 'creates an address with street, city, state, zip' do
      address = Address.new(
        street: '123 Main St',
        city: 'San Francisco',
        state: 'CA',
        zip: '94102'
      )
      expect(address.street).to eq('123 Main St')
      expect(address.city).to eq('San Francisco')
    end

    it 'is frozen (immutable)' do
      address = Address.new(street: '123 Main St', city: 'SF', state: 'CA', zip: '94102')
      expect(address).to be_frozen
    end

    it 'requires all fields' do
      expect { Address.new(street: '123 Main St', city: 'SF') }
        .to raise_error(ArgumentError)
    end
  end

  describe 'equality' do
    it 'is equal when all fields match' do
      addr1 = Address.new(street: '123 Main', city: 'SF', state: 'CA', zip: '94102')
      addr2 = Address.new(street: '123 Main', city: 'SF', state: 'CA', zip: '94102')
      expect(addr1).to eq(addr2)
    end
  end

  describe 'formatting' do
    it 'formats as single line' do
      address = Address.new(street: '123 Main St', city: 'SF', state: 'CA', zip: '94102')
      expect(address.to_s).to eq('123 Main St, SF, CA 94102')
    end
  end
end
```

### Implementation Hints

- Use keyword arguments
- Freeze after initialization
- Implement `==`, `hash`, and `eql?`
- Provide `to_s` and `to_h` methods

---

## Exercise 2: TimeSlot Value Object ⭐⭐

Create a `TimeSlot` value object for representing time ranges (like "10:00 AM - 11:00 AM").

### Requirements

```ruby
# spec/value_objects/time_slot_spec.rb
RSpec.describe TimeSlot do
  describe 'initialization' do
    it 'creates a time slot with start and end time' do
      slot = TimeSlot.new(
        Time.new(2024, 1, 1, 10, 0),
        Time.new(2024, 1, 1, 11, 0)
      )
      expect(slot.start_time).to eq(Time.new(2024, 1, 1, 10, 0))
      expect(slot.duration_minutes).to eq(60)
    end

    it 'raises error when start is after end' do
      expect do
        TimeSlot.new(
          Time.new(2024, 1, 1, 11, 0),
          Time.new(2024, 1, 1, 10, 0)
        )
      end.to raise_error(ArgumentError, /before/)
    end
  end

  describe 'overlaps?' do
    let(:slot1) { TimeSlot.new(Time.new(2024, 1, 1, 10, 0), Time.new(2024, 1, 1, 11, 0)) }

    it 'returns true when slots overlap' do
      slot2 = TimeSlot.new(Time.new(2024, 1, 1, 10, 30), Time.new(2024, 1, 1, 11, 30))
      expect(slot1.overlaps?(slot2)).to be true
    end

    it 'returns false when slots do not overlap' do
      slot2 = TimeSlot.new(Time.new(2024, 1, 1, 11, 0), Time.new(2024, 1, 1, 12, 0))
      expect(slot1.overlaps?(slot2)).to be false
    end
  end

  describe 'formatting' do
    it 'formats with AM/PM' do
      slot = TimeSlot.new(Time.new(2024, 1, 1, 14, 0), Time.new(2024, 1, 1, 15, 30))
      expect(slot.to_s).to eq('2:00 PM - 3:30 PM')
    end
  end
end
```

### Implementation Hints

- Similar to DateRange but for Time
- Implement `duration_minutes` and `duration_hours`
- Format with 12-hour clock (AM/PM)

---

## Exercise 3: Percentage Value Object ⭐

Create a `Percentage` value object for representing discounts, tax rates, etc.

### Requirements

```ruby
# spec/value_objects/percentage_spec.rb
RSpec.describe Percentage do
  describe 'initialization' do
    it 'creates a percentage from a decimal (0.25 = 25%)' do
      percent = Percentage.new(0.25)
      expect(percent.value).to eq(0.25)
      expect(percent.to_s).to eq('25.0%')
    end

    it 'raises error for values < 0' do
      expect { Percentage.new(-0.1) }.to raise_error(ArgumentError)
    end

    it 'raises error for values > 1' do
      expect { Percentage.new(1.5) }.to raise_error(ArgumentError)
    end
  end

  describe 'of method' do
    it 'calculates percentage of a number' do
      percent = Percentage.new(0.2)  # 20%
      expect(percent.of(100)).to eq(20)
    end

    it 'calculates percentage of Money' do
      percent = Percentage.new(0.1)  # 10%
      amount = Money.new(100, 'USD')
      result = percent.of(amount)
      expect(result).to eq(Money.new(10, 'USD'))
    end
  end

  describe 'arithmetic' do
    it 'adds two percentages' do
      p1 = Percentage.new(0.1)  # 10%
      p2 = Percentage.new(0.05) # 5%
      result = p1 + p2
      expect(result).to eq(Percentage.new(0.15))
    end
  end
end
```

### Implementation Hints

- Store as decimal (0.25, not 25)
- Validate 0 <= value <= 1
- Implement `of` method that works with numbers AND Money
- Format as "25.0%"

---

## Exercise 4: EventForm Object ⭐⭐

Create an `EventForm` that validates event creation input.

### Requirements

```ruby
# spec/forms/event_form_spec.rb
RSpec.describe EventForm do
  describe 'validation' do
    it 'is valid with all required fields' do
      form = EventForm.new(
        name: 'Ruby Conference',
        description: 'Annual Ruby event',
        venue_name: 'Convention Center',
        start_time: '2024-06-01 10:00',
        end_time: '2024-06-01 18:00',
        total_seats: '500',
        base_price: '100'
      )
      expect(form).to be_valid
    end

    it 'requires event name' do
      form = EventForm.new(description: 'Event')
      expect(form).not_to be_valid
      expect(form.errors[:name]).to include("can't be blank")
    end

    it 'validates start_time is before end_time' do
      form = EventForm.new(
        name: 'Event',
        description: 'Test',
        venue_name: 'Venue',
        start_time: '2024-06-01 18:00',
        end_time: '2024-06-01 10:00',  # After start!
        total_seats: '100',
        base_price: '50'
      )
      expect(form).not_to be_valid
      expect(form.errors[:end_time]).to include('must be after start time')
    end

    it 'validates total_seats is positive' do
      form = EventForm.new(
        name: 'Event',
        description: 'Test',
        venue_name: 'Venue',
        start_time: '2024-06-01 10:00',
        end_time: '2024-06-01 18:00',
        total_seats: '0',
        base_price: '50'
      )
      expect(form).not_to be_valid
      expect(form.errors[:total_seats]).to include('must be positive')
    end

    it 'validates base_price is positive' do
      form = EventForm.new(
        name: 'Event',
        description: 'Test',
        venue_name: 'Venue',
        start_time: '2024-06-01 10:00',
        end_time: '2024-06-01 18:00',
        total_seats: '100',
        base_price: '-10'
      )
      expect(form).not_to be_valid
      expect(form.errors[:base_price]).to include('must be positive')
    end
  end

  describe '#to_h' do
    it 'coerces string dates to Time objects' do
      form = EventForm.new(
        name: 'Event',
        description: 'Test',
        venue_name: 'Venue',
        start_time: '2024-06-01 10:00',
        end_time: '2024-06-01 18:00',
        total_seats: '100',
        base_price: '50'
      )

      result = form.to_h
      expect(result[:start_time]).to be_a(Time)
      expect(result[:total_seats]).to be_a(Integer)
      expect(result[:base_price]).to be_a(Money)  # Coerce to Money!
    end
  end
end
```

### Implementation Hints

- Parse time strings with `Time.parse`
- Convert base_price string to Money object
- Validate start_time < end_time
- Validate positive integers for seats/price

---

## Exercise 5: Discount Value Object (CHALLENGE) ⭐⭐⭐

Create a flexible `Discount` value object that can represent different discount types.

### Requirements

```ruby
# spec/value_objects/discount_spec.rb
RSpec.describe Discount do
  describe 'percentage discount' do
    it 'applies percentage discount' do
      discount = Discount.percentage(20)  # 20% off
      price = Money.new(100, 'USD')

      result = discount.apply(price)
      expect(result).to eq(Money.new(80, 'USD'))
    end
  end

  describe 'fixed amount discount' do
    it 'applies fixed amount discount' do
      discount = Discount.fixed(Money.new(15, 'USD'))
      price = Money.new(100, 'USD')

      result = discount.apply(price)
      expect(result).to eq(Money.new(85, 'USD'))
    end

    it 'does not go below zero' do
      discount = Discount.fixed(Money.new(150, 'USD'))
      price = Money.new(100, 'USD')

      result = discount.apply(price)
      expect(result).to eq(Money.new(0, 'USD'))
    end
  end

  describe 'buy X get Y free' do
    it 'applies bulk discount' do
      discount = Discount.bulk(buy: 2, get: 1)  # Buy 2, get 1 free
      price = Money.new(100, 'USD')

      # 3 items: pay for 2
      result = discount.apply(price, quantity: 3)
      expect(result).to eq(Money.new(200, 'USD'))

      # 6 items: pay for 4
      result = discount.apply(price, quantity: 6)
      expect(result).to eq(Money.new(400, 'USD'))
    end
  end

  describe 'combination' do
    it 'can combine multiple discounts' do
      d1 = Discount.percentage(10)  # 10% off
      d2 = Discount.fixed(Money.new(5, 'USD'))

      combined = d1.then(d2)
      price = Money.new(100, 'USD')

      # Apply 10% first: 100 → 90
      # Then $5 off: 90 → 85
      result = combined.apply(price)
      expect(result).to eq(Money.new(85, 'USD'))
    end
  end
end
```

### Implementation Hints

- Use factory methods: `Discount.percentage`, `Discount.fixed`, `Discount.bulk`
- Store discount type and parameters
- Implement `apply(price, quantity: 1)` method
- For combination, use Chain of Responsibility pattern
- This is HARD - plan it out first!

---

## Exercise 6: Update BookingService (INTEGRATION) ⭐⭐⭐

Update your existing `BookingService` to use the new value objects and form object.

### Requirements

1. Accept a `BookingForm` instead of raw parameters
2. Use `Money` for calculating total price
3. Use `TicketType` for pricing
4. Return a `Booking` that includes `Money` for total

```ruby
# Updated BookingService
RSpec.describe BookingService do
  let(:event_repository) { EventRepository.new }
  let(:service) { BookingService.new(event_repository) }

  describe '#book_with_form' do
    it 'books tickets using form object and value objects' do
      # Setup
      base_price = Money.new(100, 'USD')
      event = Event.new(
        name: 'Conference',
        # ...
        base_price: base_price
      )
      event_repository.add(event)

      # Form
      form = BookingForm.new(
        event_name: 'Conference',
        seats: '2',
        ticket_type: 'vip',
        email: 'user@example.com'
      )

      # Book
      result = service.book_with_form(form)

      # Verify
      expect(result).to be_success
      booking = result.value
      expect(booking.total_price).to eq(Money.new(400, 'USD'))  # 2 VIP @ $200 each
      expect(booking.ticket_type).to be_a(VIPTicket)
    end
  end
end
```

### Implementation Hints

- First validate the form: `return Result.failure unless form.valid?`
- Create the appropriate TicketType based on `form.ticket_type`
- Calculate `total_price = ticket.price * form.seats`
- Return a Booking struct with Money values

---

## Bonus Challenges 🔥

### 1. Currency Converter

Create a `CurrencyConverter` that can convert between currencies:

```ruby
converter = CurrencyConverter.new(exchange_rates: { 'EUR' => 0.85 })
usd = Money.new(100, 'USD')
eur = converter.convert(usd, to: 'EUR')  # => Money.new(85, 'EUR')
```

### 2. Pricing Strategies

Create different pricing strategies (EarlyBird, LastMinute, SeasonalPricing) that modify base prices.

### 3. Form Composition

Create a `TicketPurchaseForm` that composes `BookingForm` + `PaymentForm` + `ContactForm`.

---

## Testing Checklist

For each value object, make sure you test:

- [ ] Initialization with valid data
- [ ] Validation (reject invalid data)
- [ ] Immutability (frozen?)
- [ ] Value equality (`==`)
- [ ] Hash equality (can use as hash key?)
- [ ] Formatting (to_s, to_h)
- [ ] Domain operations (specific to each object)

For form objects, test:

- [ ] Validation for each field
- [ ] Multiple errors at once
- [ ] Type coercion in `to_h`
- [ ] Error messages are user-friendly
- [ ] Edge cases (nil, empty string, wrong type)

---

## Run Your Tests

```bash
# All value object tests
docker compose run --rm app bundle exec rspec spec/value_objects/

# All form object tests
docker compose run --rm app bundle exec rspec spec/forms/

# Specific test
docker compose run --rm app bundle exec rspec spec/value_objects/address_spec.rb

# With coverage
docker compose run --rm app bundle exec rspec

# Demo
docker compose run --rm app ruby day_5_demo.rb
```

---

## Solutions

Solutions will be provided after you attempt the exercises. Focus on:

1. TDD - Write failing test first!
2. Immutability - Always freeze value objects
3. Value equality - Implement ==, hash, eql?
4. Clear separation - Forms validate, value objects encapsulate domain

Good luck! 🚀

**Remember: Tomorrow we refactor the entire project structure, so make sure everything works before then!**
