# Day 2 Practical Exercises

Complete these exercises in order using strict TDD (test first!). They build on the EventRepository we created today.

---

## Exercise 1: Add `find_by_venue` Method (EASY)

**Goal:** Practice `find` vs `select` and exact matching

### Requirements

Add a method to EventRepository that finds the **first** event at a specific venue (exact match).

### Tests to Write

```ruby
# In spec/event_repository_spec.rb

describe '#find_by_venue' do
  subject(:repo) { described_class.new([event1, event2, event3]) }

  context 'when venue exists' do
    it 'returns the first event at that venue' do
      result = repo.find_by_venue('San Francisco Convention Center')
      expect(result).to eq(event1)
    end
  end

  context 'when venue does not exist' do
    it 'returns nil' do
      result = repo.find_by_venue('Nonexistent Venue')
      expect(result).to be_nil
    end
  end

  context 'when multiple events at same venue' do
    let(:event4) do
      Event.new(
        name: 'Another Ruby Event',
        description: 'More Ruby',
        venue: 'San Francisco Convention Center',
        start_time: Time.new(2026, 9, 1),
        end_time: Time.new(2026, 9, 2),
        total_seats: 200
      )
    end

    it 'returns the first one' do
      repo.add(event4)
      result = repo.find_by_venue('San Francisco Convention Center')
      expect(result).to eq(event1)  # First one added
    end
  end
end
```

### Implementation Hints

1. Use `find` method (not `select`)
2. Compare `event.venue` with exact string match
3. Will return `nil` automatically if not found

### Questions to Think About

1. Why use `find` instead of `select` here?
2. Should this be case-sensitive? Why or why not?
3. How would you modify this to be case-insensitive?

---

## Exercise 2: Filter by Seat Availability Range (MEDIUM)

**Goal:** Practice filtering with ranges and compound conditions

### Requirements

Add a method that filters events by a range of available seats.

### Tests to Write

```ruby
describe '#filter_by_seat_range' do
  let(:events) do
    [
      Event.new(name: 'Small', description: 'D', venue: 'V',
                start_time: Time.now, end_time: Time.now + 1, total_seats: 20),
      Event.new(name: 'Medium', description: 'D', venue: 'V',
                start_time: Time.now, end_time: Time.now + 1, total_seats: 100),
      Event.new(name: 'Large', description: 'D', venue: 'V',
                start_time: Time.now, end_time: Time.now + 1, total_seats: 500)
    ]
  end

  subject(:repo) { described_class.new(events) }

  it 'filters events within seat range' do
    results = repo.filter_by_seat_range(50, 200)
    expect(results).to contain_exactly(events[1])  # Medium event
  end

  it 'includes boundary values' do
    results = repo.filter_by_seat_range(100, 500)
    expect(results).to contain_exactly(events[1], events[2])
  end

  it 'returns empty array when no matches' do
    results = repo.filter_by_seat_range(1000, 2000)
    expect(results).to be_empty
  end

  it 'works with min = max' do
    results = repo.filter_by_seat_range(100, 100)
    expect(results).to contain_exactly(events[1])
  end
end
```

### Implementation Hints

1. Use `select` with a compound condition
2. Check `event.total_seats >= min && event.total_seats <= max`
3. Alternative: Use Range with `cover?` or `include?`

### Bonus Challenge

Implement using a Range:

```ruby
def filter_by_seat_range(min, max)
  range = (min..max)
  @events.select { |event| range.cover?(event.total_seats) }
end
```

---

## Exercise 3: Upcoming Events (MEDIUM)

**Goal:** Practice working with Time and relative filtering

### Requirements

Add a method that returns events starting in the future (after current time).

### Tests to Write

```ruby
describe '#upcoming_events' do
  let(:past_event) do
    Event.new(
      name: 'Past Event',
      description: 'Already happened',
      venue: 'V',
      start_time: Time.now - 86400,  # Yesterday
      end_time: Time.now - 3600,
      total_seats: 100
    )
  end

  let(:future_event) do
    Event.new(
      name: 'Future Event',
      description: 'Coming soon',
      venue: 'V',
      start_time: Time.now + 86400,  # Tomorrow
      end_time: Time.now + 90000,
      total_seats: 100
    )
  end

  subject(:repo) { described_class.new([past_event, future_event]) }

  it 'returns only events starting in the future' do
    results = repo.upcoming_events
    expect(results).to contain_exactly(future_event)
  end

  it 'excludes events that already started' do
    results = repo.upcoming_events
    expect(results).not_to include(past_event)
  end

  it 'sorts by start time (soonest first)' do
    event_in_week = Event.new(
      name: 'Next Week',
      description: 'D',
      venue: 'V',
      start_time: Time.now + 604800,  # 1 week
      end_time: Time.now + 608400,
      total_seats: 50
    )

    repo.add(event_in_week)
    results = repo.upcoming_events
    expect(results.first).to eq(future_event)  # Tomorrow comes first
  end
end
```

### Implementation Hints

1. Use `select` to filter by `start_time > Time.now`
2. Chain with `sort_by(&:start_time)` for sorting
3. Consider: Should "starting now" count as upcoming?

### Questions

1. What happens if someone runs this test tomorrow?
2. How would you make this test time-independent?
3. Should we use `Time.now` or accept a parameter?

---

## Exercise 4: Create Your Own Enumerable Class (ADVANCED)

**Goal:** Understand how Enumerable works by implementing it

### Requirements

Create a `EventCollection` class that includes Enumerable and implements `each`.

### Starter Code

```ruby
# lib/event_collection.rb
class EventCollection
  include Enumerable  # This gives us map, select, find, etc. for FREE!

  def initialize(events = [])
    @events = events
  end

  # The ONLY method you need to implement for Enumerable!
  # All other methods (map, select, find, etc.) are defined in terms of each
  def each(&block)
    # Your implementation here
    # Hint: @events.each(&block)
  end
end
```

### Tests to Write

```ruby
# spec/event_collection_spec.rb
require 'spec_helper'

RSpec.describe EventCollection do
  let(:event1) { Event.new(...) }
  let(:event2) { Event.new(...) }
  subject(:collection) { described_class.new([event1, event2]) }

  describe 'Enumerable methods' do
    it 'implements each' do
      names = []
      collection.each { |e| names << e.name }
      expect(names).to eq([event1.name, event2.name])
    end

    it 'gets map for free from Enumerable' do
      names = collection.map(&:name)
      expect(names).to eq([event1.name, event2.name])
    end

    it 'gets select for free from Enumerable' do
      # Assuming event1 has more seats than event2
      results = collection.select { |e| e.total_seats > 100 }
      expect(results).to include(event1)
    end

    it 'gets find for free from Enumerable' do
      result = collection.find { |e| e.name == event1.name }
      expect(result).to eq(event1)
    end
  end
end
```

### What You'll Learn

By including `Enumerable` and defining `each`, you get 40+ methods for free:

- map, select, find, reduce
- any?, all?, none?
- max, min, max_by, min_by
- group_by, partition, chunk
- And many more!

This is the **power of Ruby mixins**.

---

## Exercise 5: Query Chaining Pattern (ADVANCED)

**Goal:** Implement fluent interface for complex queries

### Requirements

Modify EventRepository to support chaining like:

```ruby
repo
  .where { |e| e.venue.include?('SF') }
  .where { |e| e.available_seats > 0 }
  .order_by(:start_time)
  .limit(10)
  .results
```

### Implementation Strategy

```ruby
class EventRepository
  # Returns a new QueryBuilder with filtered events
  def where(&block)
    QueryBuilder.new(@events.select(&block))
  end
end

class QueryBuilder
  def initialize(events)
    @events = events
  end

  def where(&block)
    QueryBuilder.new(@events.select(&block))
  end

  def order_by(attribute)
    QueryBuilder.new(@events.sort_by { |e| e.send(attribute) })
  end

  def limit(count)
    QueryBuilder.new(@events.first(count))
  end

  def results
    @events.dup
  end
end
```

### Tests to Write

```ruby
describe 'query chaining' do
  it 'supports multiple where clauses' do
    results = repo
      .where { |e| e.venue.include?('SF') }
      .where { |e| e.total_seats > 100 }
      .results

    expect(results).to all(satisfy { |e| e.venue.include?('SF') })
    expect(results).to all(satisfy { |e| e.total_seats > 100 })
  end

  it 'supports ordering' do
    results = repo
      .where { |e| e.available_seats > 0 }
      .order_by(:start_time)
      .results

    expect(results).to eq(results.sort_by(&:start_time))
  end

  it 'supports limit' do
    results = repo
      .where { |e| e.available_seats > 0 }
      .limit(2)
      .results

    expect(results.size).to eq(2)
  end
end
```

This pattern is used by ActiveRecord! You're learning how Rails works.

---

## Exercise 6: Implement Lazy Search (EXPERT)

**Goal:** Understand lazy evaluation in practice

### Requirements

Create a `lazy_search` method that returns a lazy enumerator for memory efficiency.

### Usage Example

```ruby
# Without lazy - loads all events into memory
all_matching = repo.search_by_name('Ruby')  # Array of all matches
first_five = all_matching.first(5)

# With lazy - only processes until 5 found
first_five = repo.lazy_search('Ruby').first(5)
# Stops searching after finding 5 matches!
```

### Implementation

```ruby
def lazy_search(query)
  @events.lazy.select { |event| event.name.downcase.include?(query.downcase) }
end
```

### Tests

```ruby
describe '#lazy_search' do
  it 'returns a lazy enumerator' do
    result = repo.lazy_search('Ruby')
    expect(result).to be_a(Enumerator::Lazy)
  end

  it 'can be materialized with force' do
    result = repo.lazy_search('Ruby').force
    expect(result).to be_a(Array)
  end

  it 'supports chaining' do
    result = repo
      .lazy_search('Ruby')
      .select { |e| e.total_seats > 100 }
      .first(3)

    expect(result.size).to be <= 3
  end
end
```

---

## Bonus Exercise: Event Statistics Module

**Goal:** Practice Enumerable methods with real calculations

### Requirements

Create a module with statistics methods:

```ruby
module EventStatistics
  def average_capacity
    return 0 if @events.empty?
    @events.sum(&:total_seats).fdiv(@events.size)
  end

  def largest_event
    @events.max_by(&:total_seats)
  end

  def smallest_event
    @events.min_by(&:total_seats)
  end

  def total_capacity
    @events.sum(&:total_seats)
  end

  def events_by_month
    @events.group_by { |e| e.start_time.strftime('%Y-%m') }
  end

  def venue_distribution
    @events.map(&:venue).tally
  end
end

# Include in EventRepository
class EventRepository
  include EventStatistics
  # ...
end
```

### Tests

Test each statistical method thoroughly!

---

## Reflection Questions

After completing these exercises:

1. **When should you use `find` vs `select`?**
   - find: Returns first match (single element)
   - select: Returns all matches (array)

2. **What's the difference between `map` and `each`?**
   - map: Returns new array with transformed values
   - each: Returns original array, used for side effects

3. **Why is defensive copying important?**
   - Prevents external code from mutating internal state
   - Encapsulation principle

4. **When should you use lazy evaluation?**
   - Large collections
   - Only need first N results
   - Multiple chained operations

5. **What makes Enumerable so powerful?**
   - Define `each` once, get 40+ methods free
   - Consistent interface across all collections
   - Enables functional programming patterns

---

## Next Steps

1. ✅ Complete exercises in order
2. ✅ Run tests to verify (100% coverage!)
3. ✅ Experiment with different Enumerable methods
4. ✅ Read Ruby's Enumerable documentation
5. ✅ Ready for Day 3? Let me know!

**Remember:** The best way to learn is by doing. Write the tests first, watch them fail, then make them pass!
