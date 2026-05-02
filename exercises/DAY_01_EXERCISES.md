# Day 1 Practical Exercises

These exercises will reinforce your understanding of Ruby basics and TDD. Complete them in order, following strict TDD (test first!).

---

## Exercise 1: Add `sold_out?` method (EASY)

**Goal:** Practice basic TDD cycle and boolean methods

### Step 1: Write the test FIRST

Add to `spec/event_spec.rb`:

```ruby
describe '#sold_out?' do
  context 'when seats are available' do
    subject(:event) do
      described_class.new(
        name: 'Conference',
        description: 'A conference',
        venue: 'Center',
        start_time: Time.now,
        end_time: Time.now + 3600,
        total_seats: 100
      )
    end

    it 'returns false' do
      expect(event.sold_out?).to be false
    end
  end

  context 'when no seats are available' do
    subject(:event) do
      described_class.new(
        name: 'Conference',
        description: 'A conference',
        venue: 'Center',
        start_time: Time.now,
        end_time: Time.now + 3600,
        total_seats: 100
      )
    end

    before do
      # TODO: You'll need a way to reduce available_seats to 0
      # This reveals a design issue we'll address in Exercise 2!
    end

    it 'returns true' do
      expect(event.sold_out?).to be true
    end
  end
end
```

### Step 2: Run the test (RED)
```bash
make test
# Should see: undefined method `sold_out?'
```

### Step 3: Implement (GREEN)

Add to `lib/event.rb`:

```ruby
def sold_out?
  # Your implementation here
  # Hint: Compare available_seats to something
end
```

### Step 4: Run the test (GREEN)
```bash
make test
# All tests should pass
```

### Questions:
1. Why use `be false` instead of `eq(false)`?
2. How would you test the edge case where `available_seats` is exactly 0?

---

## Exercise 2: Add `reserve_seats` method (MEDIUM)

**Goal:** Practice mutating methods and error handling

**Challenge:** This reveals a design decision - should Event be mutable?

### Design Decision Point

Option A: Mutate the event (changes @available_seats)
```ruby
event.reserve_seats(5)
event.available_seats  # => 95
```

Option B: Return a new event (immutable)
```ruby
new_event = event.reserve_seats(5)
event.available_seats      # => 100 (unchanged)
new_event.available_seats  # => 95
```

**For this exercise, choose Option A (mutation)** to learn Ruby's mutable patterns. We'll refactor to immutability later.

### Tests to Write

```ruby
describe '#reserve_seats' do
  let(:event) do
    described_class.new(
      name: 'Conference',
      description: 'A conference',
      venue: 'Center',
      start_time: Time.now,
      end_time: Time.now + 3600,
      total_seats: 100
    )
  end

  context 'when enough seats are available' do
    it 'reduces available seats by the requested amount' do
      event.reserve_seats(10)
      expect(event.available_seats).to eq(90)
    end

    it 'returns the number of seats reserved' do
      result = event.reserve_seats(10)
      expect(result).to eq(10)
    end
  end

  context 'when not enough seats are available' do
    before do
      event.reserve_seats(95)  # Leave only 5 available
    end

    it 'raises an error' do
      expect { event.reserve_seats(10) }.to raise_error(
        ArgumentError,
        /not enough seats available/
      )
    end

    it 'does not modify available seats' do
      expect { event.reserve_seats(10) }.to raise_error(ArgumentError)
      expect(event.available_seats).to eq(5)
    end
  end

  context 'when requesting zero seats' do
    it 'raises an error' do
      expect { event.reserve_seats(0) }.to raise_error(
        ArgumentError,
        /must reserve at least 1 seat/
      )
    end
  end

  context 'when requesting negative seats' do
    it 'raises an error' do
      expect { event.reserve_seats(-5) }.to raise_error(
        ArgumentError,
        /must reserve at least 1 seat/
      )
    end
  end
end
```

### Implementation Hints

1. Add `attr_writer :available_seats` or make it accessible
2. Validate count is positive
3. Validate count <= available_seats
4. Reduce available_seats
5. Return the count

### Questions:
1. Why test that available_seats doesn't change when an error is raised?
2. Should we have a separate method for canceling reservations?
3. What are the trade-offs of mutation vs immutability?

---

## Exercise 3: Validate Event Name Length (MEDIUM)

**Goal:** Practice validation logic and RSpec shared examples

### Requirements

1. Event name must be at least 3 characters
2. Event name must be at most 100 characters
3. Error messages should be descriptive

### Tests Structure

```ruby
describe '#initialize' do
  context 'when validating name length' do
    let(:base_params) do
      {
        description: 'Description',
        venue: 'Venue',
        start_time: Time.now,
        end_time: Time.now + 3600,
        total_seats: 100
      }
    end

    context 'when name is too short' do
      it 'raises an error for 2 characters' do
        # Your test here
      end

      it 'raises an error for 1 character' do
        # Your test here
      end

      it 'raises an error for empty string' do
        # Already tested, but good to verify error message
      end
    end

    context 'when name is too long' do
      it 'raises an error for 101 characters' do
        long_name = 'a' * 101
        # Your test here
      end
    end

    context 'when name length is valid' do
      it 'accepts 3 characters (minimum)' do
        event = described_class.new(
          **base_params,
          name: 'abc'
        )
        expect(event.name).to eq('abc')
      end

      it 'accepts 100 characters (maximum)' do
        name = 'a' * 100
        event = described_class.new(
          **base_params,
          name: name
        )
        expect(event.name).to eq(name)
      end

      it 'accepts 50 characters (middle)' do
        # Your test here
      end
    end
  end
end
```

### Implementation Hints

1. Add validation in `validate_required_fields` or create `validate_name`
2. Use `String#length` or `String#size`
3. Provide clear error messages

### Bonus Challenge: Use RSpec Shared Examples

```ruby
# In spec/event_spec.rb
RSpec.shared_examples 'invalid name length' do |name_value, expected_error|
  it "raises error for '#{name_value}'" do
    expect do
      described_class.new(
        name: name_value,
        # ... other params
      )
    end.to raise_error(ArgumentError, expected_error)
  end
end

# Then use it:
context 'when name is too short' do
  include_examples 'invalid name length', 'ab', /at least 3 characters/
  include_examples 'invalid name length', 'a', /at least 3 characters/
end
```

---

## Exercise 4: Add `Venue` Class (ADVANCED)

**Goal:** Create a second class using TDD, practice object composition

### Requirements

Create a `Venue` class with:
- name (required, 3-100 characters)
- address (required)
- capacity (required, positive integer)
- `to_s` method

Then modify Event to:
- Accept a `Venue` object instead of venue string
- Validate that venue.capacity >= total_seats

### Test Structure

```ruby
# spec/venue_spec.rb
require 'spec_helper'

RSpec.describe Venue do
  describe '#initialize' do
    context 'when all required attributes are provided' do
      # Your tests here
    end

    context 'when validating attributes' do
      # Your tests here
    end
  end

  describe '#to_s' do
    # Your tests here
  end
end
```

### Then update Event tests:

```ruby
# spec/event_spec.rb
describe Event do
  let(:venue) do
    Venue.new(
      name: 'Convention Center',
      address: '123 Main St',
      capacity: 1000
    )
  end

  describe '#initialize' do
    context 'when venue capacity is less than total_seats' do
      it 'raises an error' do
        expect do
          described_class.new(
            name: 'Big Event',
            description: 'Too big for venue',
            venue: venue,
            start_time: Time.now,
            end_time: Time.now + 3600,
            total_seats: 2000  # More than venue.capacity!
          )
        end.to raise_error(ArgumentError, /exceeds venue capacity/)
      end
    end
  end
end
```

---

## Exercise 5: Refactor to Immutability (ADVANCED)

**Goal:** Understand immutability and `freeze`

### Current Problem

```ruby
event = Event.new(...)
event.name  # => "RubyConf"

# Can we mutate the string?
event.name.upcase!
event.name  # => "RUBYCONF" (mutated!)
```

### Requirements

1. Make all string attributes immutable using `freeze`
2. Test that strings can't be mutated
3. Consider: Should `reserve_seats` return a new Event instead?

### Test Example

```ruby
describe 'immutability' do
  subject(:event) { described_class.new(...) }

  it 'freezes the name string' do
    expect(event.name).to be_frozen
  end

  it 'cannot mutate name' do
    expect { event.name.upcase! }.to raise_error(FrozenError)
  end
end
```

---

## Reflection Questions

After completing these exercises, think about:

1. **TDD Benefits**: How did writing tests first change your approach?
2. **Mutation vs Immutability**: Which feels more natural? Why?
3. **Validation Placement**: Should validations be in the model or elsewhere?
4. **Error Messages**: How descriptive should they be?
5. **Test Coverage**: Is 100% coverage always necessary?

---

## Next Steps

Once you've completed these exercises:

1. Run `make test` - all tests should pass
2. Run `make lint` - code should follow style guide
3. Check coverage - should still be 100%
4. Review your code - any duplication? Any unclear names?

**Ready for Day 2?** We'll build an EventRepository with in-memory search using Ruby's Enumerable module!
