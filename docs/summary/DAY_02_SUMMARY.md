# Day 2 Summary: Collections, Enumerable & Functional Patterns

## What We Built Today

✅ EventRepository class with rich querying capabilities  
✅ In-memory storage using Arrays  
✅ Search, filter, and sort operations  
✅ Comprehensive test suite using shared examples  
✅ Understanding of Ruby's Enumerable module

---

## Key Ruby Concepts Learned

### 1. **Arrays - Ordered Collections**

```ruby
events = [event1, event2, event3]

# Access by index
events[0]       # First element
events[-1]      # Last element (negative indexing!)
events[0..2]    # Range access (first 3)

# Common operations
events << event4     # Append
events.size         # Count
events.empty?       # Check if empty
events.first        # First element
events.last         # Last element
```

**WHY negative indexing?** Common pattern - access from end without knowing length.

### 2. **Hashes - Key-Value Pairs**

```ruby
# String keys
person = { 'name' => 'Alice', 'age' => 30 }

# Symbol keys (PREFERRED!)
event_data = { name: 'RubyConf', seats: 500 }

# Modern syntax (syntactic sugar)
{ name: 'value' }  # Same as { :name => 'value' }
```

**When to use symbols vs strings for keys:**

- **Symbols**: Fixed identifiers, hash keys, internal constants
- **Strings**: User input, data that needs manipulation

**WHY symbols?** Immutable, unique in memory, perfect for identifiers.

### 3. **Enumerable Module - Ruby's Secret Weapon**

Every Ruby collection (Array, Hash, Range, etc.) includes Enumerable. This gives us powerful methods:

#### **map** - Transform each element

```ruby
names = events.map { |e| e.name }
# Returns array of names

# Symbol-to-proc shorthand
names = events.map(&:name)  # Same thing!
```

**WHY it's called map?** Maps one collection to another.

#### **select** - Filter elements (keep matches)

```ruby
big_events = events.select { |e| e.total_seats >= 500 }
# Returns array of events with 500+ seats

# Also called 'filter' in Ruby 2.6+
big_events = events.filter { |e| e.total_seats >= 500 }
```

**WHY select?** Selects elements that match the condition.

#### **reject** - Opposite of select (remove matches)

```ruby
small_events = events.reject { |e| e.total_seats >= 500 }
# Returns events with < 500 seats
```

#### **find** - Get first match

```ruby
ruby_event = events.find { |e| e.name.include?('Ruby') }
# Returns first matching event or nil

# Also called 'detect'
ruby_event = events.detect { |e| e.name.include?('Ruby') }
```

**WHY find vs select?** Returns single element, not array.

#### **reduce** - Combine into single value

```ruby
total_seats = events.reduce(0) { |sum, e| sum + e.total_seats }
# Returns total of all seats

# Also called 'inject'
total_seats = events.inject(0) { |sum, e| sum + e.total_seats }

# Modern Ruby: use sum
total_seats = events.sum(&:total_seats)
```

**WHY reduce?** Reduces collection to single value.

#### **any? / all? / none?** - Boolean queries

```ruby
events.any? { |e| e.total_seats > 1000 }   # Is any event huge?
events.all? { |e| e.available_seats > 0 }  # All have seats?
events.none? { |e| e.name.empty? }         # No empty names?
```

#### **sort_by** - Sort by attribute

```ruby
by_date = events.sort_by { |e| e.start_time }
# Sorts ascending

# Symbol-to-proc
by_date = events.sort_by(&:start_time)

# Descending: negate or reverse
by_seats_desc = events.sort_by { |e| -e.total_seats }
# OR
by_seats_desc = events.sort_by(&:total_seats).reverse
```

#### **group_by** - Group into hash

```ruby
by_month = events.group_by { |e| e.start_time.month }
# Returns hash: { 6 => [event1, event2], 7 => [event3] }

by_size = events.group_by { |e| e.total_seats >= 500 ? 'large' : 'small' }
# Returns hash: { 'large' => [...], 'small' => [...] }
```

### 4. **Blocks - Ruby's Closures**

A block is an anonymous chunk of code passed to a method:

```ruby
# Curly brace syntax (single line)
events.select { |e| e.available_seats > 0 }

# do...end syntax (multi-line)
events.select do |e|
  venue_ok = e.venue.include?('SF')
  seats_ok = e.available_seats > 0
  venue_ok && seats_ok
end
```

**When to use { } vs do...end?**

- `{ }` for simple one-liners
- `do...end` for multi-line blocks

**Blocks are closures** - they capture variables from outer scope:

```ruby
min_seats = 100
large_events = events.select { |e| e.total_seats >= min_seats }
# Block "closes over" min_seats variable
```

### 5. **Symbol-to-Proc (&:method_name)**

One of Ruby's most elegant features:

```ruby
# Long form
events.map { |e| e.name }

# Short form (symbol-to-proc)
events.map(&:name)

# How it works:
# 1. :name is a symbol
# 2. & calls Symbol#to_proc, converting to: { |obj| obj.send(:name) }
# 3. Method passes the proc to map
```

**When to use:**

- Calling a single method with no arguments
- No additional logic needed

**When NOT to use:**

- Multiple operations: `{ |e| e.name.upcase }`
- Passing arguments: `{ |e| e.start_time.strftime('%Y') }`

### 6. **Method Chaining**

Each Enumerable method returns a collection, allowing chaining:

```ruby
results = events
  .select { |e| e.venue.include?('SF') }      # Filter by venue
  .select { |e| e.available_seats > 0 }       # Filter by availability
  .sort_by(&:start_time)                      # Sort by date
  .map(&:name)                                # Extract names

# Returns array of names
```

**Think: Unix pipes**

```bash
cat file | grep pattern | sort | uniq
```

**Benefits:**

- Readable - each step is clear
- Flexible - easy to add/remove steps
- Functional - no intermediate variables

### 7. **Lazy Evaluation**

For large collections, avoid creating intermediate arrays:

```ruby
# EAGER - Creates intermediate arrays (memory intensive!)
huge_array
  .select { |n| n.even? }  # Creates array
  .map { |n| n * 2 }       # Creates another array
  .first(10)               # Finally takes 10

# LAZY - Only computes what's needed
huge_array
  .lazy                    # Convert to lazy enumerator
  .select { |n| n.even? }
  .map { |n| n * 2 }
  .first(10)               # Stops after finding 10!

# Returns Enumerator, call .force to get array
```

**When to use lazy?**

- Huge collections (> 10,000 elements)
- Infinite sequences
- Only need first N results
- Multiple chained operations

---

## Design Patterns Learned

### Repository Pattern

**WHY?** Separate data access from business logic

```ruby
# Bad: Business logic knows about storage
class TicketBooker
  def initialize
    @events = []  # Coupled to Array implementation
  end

  def find_event
    @events.find { |e| ... }  # Business logic does data access
  end
end

# Good: Repository handles data access
class TicketBooker
  def initialize(event_repository)
    @repo = event_repository  # Inject dependency
  end

  def find_event
    @repo.find_by_name('RubyConf')  # Clean interface
  end
end
```

**Benefits:**

- Easy to test (inject mock repository)
- Easy to swap storage (Array → PostgreSQL)
- Single Responsibility (repository = data, service = logic)

### Defensive Copying

**WHY?** Prevent external code from mutating internal state

```ruby
class EventRepository
  def all
    @events.dup  # Return COPY, not original
  end
end

# Without defensive copy:
events = repo.all
events << fake_event  # Mutates repo's internal array!

# With defensive copy:
events = repo.all
events << fake_event  # Only mutates the copy
```

---

## TDD Concepts Learned

### Shared Examples

Reusable test scenarios:

```ruby
# Define shared example
RSpec.shared_examples 'returns a collection' do
  it 'returns an Array' do
    expect(result).to be_a(Array)
  end
end

# Use in multiple tests
describe '#search_by_name' do
  let(:result) { repo.search_by_name('Ruby') }
  include_examples 'returns a collection'
end

describe '#filter_by_venue' do
  let(:result) { repo.filter_by_venue('SF') }
  include_examples 'returns a collection'
end
```

**WHY?** DRY principle for tests, ensures consistency.

### Testing Collections

```ruby
# contain_exactly - matches elements regardless of order
expect(results).to contain_exactly(event1, event2)

# eq - matches exact order
expect(sorted).to eq([event1, event2, event3])

# be_empty - clearer than eq([])
expect(results).to be_empty

# include - check for presence
expect(results).to include(event1)
```

---

## Ruby Idioms & Best Practices

### 1. **Prefer Enumerable over Loops**

```ruby
# Bad (imperative)
names = []
events.each do |event|
  names << event.name
end

# Good (functional)
names = events.map(&:name)
```

### 2. **Use Symbol-to-Proc When Possible**

```ruby
# Verbose
events.sort_by { |e| e.start_time }

# Concise
events.sort_by(&:start_time)
```

### 3. **Chain for Readability**

```ruby
# Hard to read
available_sf_events_sorted = events.select { |e| e.available_seats > 0 }.select { |e| e.venue.include?('SF') }.sort_by { |e| e.start_time }

# Readable
available_sf_events_sorted = events
  .select { |e| e.available_seats > 0 }
  .select { |e| e.venue.include?('SF') }
  .sort_by(&:start_time)
```

### 4. **Boolean Method Names End with ?**

```ruby
# Ruby convention
events.any?(&:sold_out?)
events.all?(&:available?)

# NOT: is_sold_out, has_seats
```

### 5. **Use Modern Ruby Methods**

```ruby
# Ruby 2.4+
events.sum(&:total_seats)  # vs reduce(0) { |sum, e| sum + e.total_seats }

# Ruby 2.7+
counts = names.tally  # vs group_by(&:itself).transform_values(&:count)

# Ruby 3.0+
events.filter { }  # Alias for select (more familiar to other languages)
```

---

## Common Patterns Comparison

### Enumerable Method Reference

| Operation         | Method     | Returns        | Example                                         |
| ----------------- | ---------- | -------------- | ----------------------------------------------- |
| Transform all     | `map`      | Array          | `events.map(&:name)`                            |
| Filter matches    | `select`   | Array          | `events.select { \|e\| e.seats > 100 }`         |
| Remove matches    | `reject`   | Array          | `events.reject(&:sold_out?)`                    |
| First match       | `find`     | Element or nil | `events.find { \|e\| e.name == 'X' }`           |
| Combine to one    | `reduce`   | Single value   | `events.reduce(0) { \|sum, e\| sum + e.seats }` |
| Check any         | `any?`     | Boolean        | `events.any?(&:available?)`                     |
| Check all         | `all?`     | Boolean        | `events.all? { \|e\| e.seats > 0 }`             |
| Check none        | `none?`    | Boolean        | `events.none?(&:cancelled?)`                    |
| Sort              | `sort_by`  | Array          | `events.sort_by(&:date)`                        |
| Group             | `group_by` | Hash           | `events.group_by(&:venue)`                      |
| Count occurrences | `tally`    | Hash           | `venues.tally`                                  |
| Sum values        | `sum`      | Number         | `events.sum(&:seats)`                           |
| Maximum           | `max_by`   | Element        | `events.max_by(&:seats)`                        |
| Minimum           | `min_by`   | Element        | `events.min_by(&:price)`                        |

---

## Performance Considerations

### Enumerable Performance

| Operation  | Complexity      | Notes                    |
| ---------- | --------------- | ------------------------ |
| `select`   | O(n)            | Must check every element |
| `find`     | O(n) worst case | Stops at first match     |
| `map`      | O(n)            | Touches every element    |
| `sort_by`  | O(n log n)      | Standard sort complexity |
| `include?` | O(n)            | Linear search            |

**Optimization strategies:**

1. **Use `find` over `select` when you need one** - Stops early
2. **Chain selects efficiently** - More specific filters first
3. **Use `lazy` for large collections** - Avoid intermediate arrays
4. **Consider Sets for membership tests** - O(1) vs O(n)

---

## Looking Back at Day 1

### What We Added

Day 1: Single Event class  
Day 2: Collection of Events with querying

### How They Connect

```ruby
# Day 1: Create events
event1 = Event.new(...)
event2 = Event.new(...)

# Day 2: Store and query them
repo = EventRepository.new([event1, event2])
ruby_events = repo.search_by_name('Ruby')
```

---

## Looking Ahead to Day 3

Tomorrow we'll learn **Classes, Modules & Mixins**:

**Topics:**

- When to use Class vs Module
- include, extend, prepend
- Method lookup chain
- Extracting shared behavior

**We'll build:**

- `Searchable` module for reusable search logic
- `Timestampable` module for created_at/updated_at
- Better separation of concerns

**Why it matters:**
Ruby's composition model (mixins) is different from inheritance.
Understanding this is key to writing idiomatic Ruby.

---

## Exercises to Reinforce Learning

See `DAY_2_EXERCISES.md` for hands-on practice:

1. Add `find_by_venue` method
2. Implement `filter_by_available_seats` range
3. Add `upcoming_events` method
4. Create custom Enumerable class
5. Implement query chaining pattern

---

## Key Takeaways

1. ✅ **Enumerable is Ruby's superpower** - Learn it well
2. ✅ **Blocks are everywhere** - Get comfortable with them
3. ✅ **Chaining is elegant** - Embrace functional patterns
4. ✅ **Symbol-to-proc is concise** - Use when appropriate
5. ✅ **Repository pattern separates concerns** - Essential for clean code
6. ✅ **Defensive copying prevents bugs** - Return copies, not originals
7. ✅ **Lazy evaluation for performance** - Use on large collections

---

## Commands Reference

```bash
# Run the collections tutorial
docker-compose run --rm app ruby lib/collections_tutorial.rb

# Run the repository demo
docker-compose run --rm app ruby repository_demo.rb

# Run tests
docker-compose run --rm app bundle exec rspec

# Run specific test file
docker-compose run --rm app bundle exec rspec spec/event_repository_spec.rb

# Check coverage
open coverage/index.html
```

---

## Resources for Deeper Learning

- **Enumerable documentation**: https://ruby-doc.org/core/Enumerable.html
- **Blocks, Procs, Lambdas**: https://www.rubyguides.com/2016/02/ruby-procs-and-lambdas/
- **Symbol-to-Proc explained**: https://www.brianstorti.com/understanding-ruby-idioms-map-with-symbol/

---

**Great work on Day 2! 🎉**

You've mastered Ruby's collection handling and functional programming features. These are the tools you'll use every day in Ruby development.

Ready for Day 3? Let me know!
