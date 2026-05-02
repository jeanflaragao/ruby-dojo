# Day 3 Practical Exercises

Complete these exercises to master modules and mixins. Follow TDD - write tests first!

---

## Exercise 1: Create Searchable Module for EventRepository (MEDIUM)

**Goal:** Extract search functionality into a reusable module

### Requirements

Create a `Searchable` module that can be mixed into any repository class.

### Module to Create

```ruby
# lib/searchable.rb
module Searchable
  # Search by any attribute (case-insensitive partial match)
  #
  # @param attribute [Symbol] the attribute to search (e.g., :name, :description)
  # @param query [String] the search term
  # @return [Array] matching records
  def search_by(attribute, query)
    # Your implementation here
    # Hint: Use @collection or @events or whatever your storage variable is
    # Hint: Use respond_to? to check if object has the attribute
  end

  # Search across multiple attributes
  #
  # @param query [String] the search term
  # @param attributes [Array<Symbol>] attributes to search
  # @return [Array] matching records
  def search_across(query, *attributes)
    # Your implementation here
  end
end
```

### Tests to Write

```ruby
# spec/searchable_spec.rb
require 'spec_helper'

RSpec.describe Searchable do
  let(:test_class) do
    Class.new do
      include Searchable

      attr_reader :events

      def initialize(events)
        @events = events
      end
    end
  end

  let(:event1) { Event.new(name: 'RubyConf', description: 'Ruby conference', ...) }
  let(:event2) { Event.new(name: 'RailsConf', description: 'Rails conference', ...) }

  subject(:repository) { test_class.new([event1, event2]) }

  describe '#search_by' do
    it 'finds by name' do
      results = repository.search_by(:name, 'Ruby')
      expect(results).to contain_exactly(event1)
    end

    it 'is case-insensitive' do
      results = repository.search_by(:name, 'ruby')
      expect(results).to contain_exactly(event1)
    end

    it 'finds by description' do
      results = repository.search_by(:description, 'conference')
      expect(results).to contain_exactly(event1, event2)
    end
  end

  describe '#search_across' do
    it 'searches multiple attributes' do
      results = repository.search_across('Ruby', :name, :description)
      expect(results).to include(event1)
    end
  end
end
```

### Then Include in EventRepository

```ruby
class EventRepository
  include Searchable

  # Now you can use:
  # repo.search_by(:name, 'Ruby')
  # repo.search_across('conference', :name, :description)
end
```

---

## Exercise 2: Add Comparable to Event (EASY)

**Goal:** Make events comparable and sortable by start time

### Requirements

Mix Ruby's built-in `Comparable` module into Event.

### Implementation

```ruby
# In lib/event.rb or lib/event_with_modules.rb
class Event
  include Comparable  # Add this

  # Define spaceship operator
  def <=>(other)
    return nil unless other.is_a?(Event)

    start_time <=> other.start_time
  end
end
```

### Tests to Write

```ruby
# In spec/event_spec.rb
describe 'Comparable' do
  let(:early_event) do
    Event.new(
      name: 'Early Event',
      start_time: Time.new(2026, 6, 1),
      # ... other attributes
    )
  end

  let(:late_event) do
    Event.new(
      name: 'Late Event',
      start_time: Time.new(2026, 12, 1),
      # ... other attributes
    )
  end

  it 'compares events by start time' do
    expect(early_event < late_event).to be true
    expect(late_event > early_event).to be true
  end

  it 'sorts events by start time' do
    events = [late_event, early_event]
    sorted = events.sort

    expect(sorted.first).to eq(early_event)
  end

  it 'checks if event is between two dates' do
    middle_event = Event.new(
      name: 'Middle',
      start_time: Time.new(2026, 9, 1),
      # ...
    )

    expect(middle_event.between?(early_event, late_event)).to be true
  end
end
```

### What You Get For Free

Once you define `<=>`, Comparable gives you:

- `<`, `>`, `==`, `<=`, `>=`
- `between?(min, max)`
- `clamp(min, max)`

---

## Exercise 3: Create Loggable Module with Prepend (ADVANCED)

**Goal:** Add logging to methods using prepend

### Requirements

Create a module that logs method calls automatically.

### Module to Create

```ruby
# lib/loggable.rb
module Loggable
  def save
    log("Saving #{self.class.name}...")
    result = super  # Call original save method
    log("Saved #{self.class.name} successfully")
    result
  end

  def update(*args)
    log("Updating #{self.class.name}...")
    result = super
    log("Updated #{self.class.name} successfully")
    result
  end

  private

  def log(message)
    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
  end
end
```

### Usage

```ruby
class Event
  prepend Loggable  # Use prepend, not include!

  def save
    # actual save logic
  end

  def update(name:)
    @name = name
    touch
  end
end

event.save
# Output:
# [2026-05-02 10:30:00] Saving Event...
# [2026-05-02 10:30:00] Saved Event successfully
```

### Tests

```ruby
describe Loggable do
  let(:test_class) do
    Class.new do
      prepend Loggable

      def save
        'saved'
      end
    end
  end

  it 'logs before and after method' do
    obj = test_class.new

    expect { obj.save }.to output(/Saving/).to_stdout
    expect { obj.save }.to output(/Saved successfully/).to_stdout
  end

  it 'returns original method result' do
    obj = test_class.new
    expect(obj.save).to eq('saved')
  end
end
```

### Question to Think About

**Why prepend instead of include?**

- With prepend, Loggable#save runs first, then calls super to Event#save
- With include, Event#save would run, Loggable#save never called
- Prepend lets us wrap/decorate existing methods

---

## Exercise 4: Implement SoftDeletable Module (ADVANCED)

**Goal:** Add soft delete capability (mark as deleted instead of removing)

### Requirements

Objects can be marked as deleted without actually removing them.

### Module to Create

```ruby
# lib/soft_deletable.rb
module SoftDeletable
  attr_reader :deleted_at

  def delete
    @deleted_at = Time.now
    self
  end

  def deleted?
    !@deleted_at.nil?
  end

  def restore
    @deleted_at = nil
    self
  end

  def self.included(base)
    # Add a scope-like method to the class
    # This is metaprogramming - we'll cover it more later
    base.extend(ClassMethods)
  end

  module ClassMethods
    # This will be a class method on the including class
    def active
      # Override in the class to filter non-deleted records
    end
  end
end
```

### Usage in EventRepository

```ruby
class EventRepository
  def all_active
    @events.reject(&:deleted?)
  end

  def all_deleted
    @events.select(&:deleted?)
  end
end

class Event
  include SoftDeletable
  include Timestampable

  def delete
    super  # Call SoftDeletable#delete
    touch  # Update timestamp
  end
end

# Usage:
event.delete
event.deleted?  # => true
event.deleted_at  # => 2026-05-02 10:30:00

repo.all_active  # Events not deleted
repo.all_deleted  # Only deleted events

event.restore
event.deleted?  # => false
```

### Tests

```ruby
describe SoftDeletable do
  let(:event) { Event.new(name: 'Test', ...) }

  it 'marks record as deleted' do
    event.delete
    expect(event.deleted?).to be true
    expect(event.deleted_at).to be_a(Time)
  end

  it 'can be restored' do
    event.delete
    event.restore
    expect(event.deleted?).to be false
    expect(event.deleted_at).to be_nil
  end

  it 'filters deleted records from repository' do
    event1 = Event.new(name: 'Active', ...)
    event2 = Event.new(name: 'Deleted', ...)
    event2.delete

    repo = EventRepository.new([event1, event2])
    expect(repo.all_active).to contain_exactly(event1)
    expect(repo.all_deleted).to contain_exactly(event2)
  end
end
```

---

## Exercise 5: Build Serializable Module (EXPERT)

**Goal:** Convert objects to/from JSON using a module

### Requirements

Add JSON serialization to any class.

### Module to Create

```ruby
# lib/serializable.rb
require 'json'

module Serializable
  def to_json(*args)
    attributes = self.class.serializable_attributes
    hash = attributes.each_with_object({}) do |attr, h|
      value = send(attr)
      h[attr] = serialize_value(value)
    end
    hash.to_json(*args)
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def serializable_attributes(*attrs)
      @serializable_attributes = attrs if attrs.any?
      @serializable_attributes || []
    end

    def from_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)
      new(**hash)
    end
  end

  private

  def serialize_value(value)
    case value
    when Time
      value.iso8601
    when Venue, Event
      value.to_json  # Nested objects
    else
      value
    end
  end
end
```

### Usage

```ruby
class Event
  include Serializable

  serializable_attributes :name, :description, :start_time, :end_time, :total_seats

  # ... rest of class
end

event = Event.new(name: 'RubyConf', ...)
json = event.to_json
# => '{"name":"RubyConf","description":"...","start_time":"2026-06-15T09:00:00Z",...}'

restored = Event.from_json(json)
restored.name  # => "RubyConf"
```

### Tests

```ruby
describe Serializable do
  let(:event) do
    Event.new(
      name: 'RubyConf',
      description: 'Conference',
      # ...
    )
  end

  describe '#to_json' do
    it 'serializes to JSON' do
      json = event.to_json
      parsed = JSON.parse(json)

      expect(parsed['name']).to eq('RubyConf')
    end

    it 'converts Time to ISO8601' do
      json = event.to_json
      parsed = JSON.parse(json)

      expect(parsed['start_time']).to match(/\d{4}-\d{2}-\d{2}T/)
    end
  end

  describe '.from_json' do
    it 'deserializes from JSON' do
      json = event.to_json
      restored = Event.from_json(json)

      expect(restored.name).to eq(event.name)
    end
  end
end
```

---

## Bonus Exercise: Module with Configuration

**Goal:** Create a module that accepts configuration

### Implementation

```ruby
module Cacheable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def cache_config
      @cache_config ||= { ttl: 3600, enabled: true }
    end

    def configure_cache(ttl: nil, enabled: nil)
      cache_config[:ttl] = ttl if ttl
      cache_config[:enabled] = enabled unless enabled.nil?
    end
  end

  def cached_fetch(&block)
    return block.call unless self.class.cache_config[:enabled]

    @cache ||= {}
    cache_key = block.source_location.join(':')

    if @cache[cache_key] && !expired?(cache_key)
      @cache[cache_key][:value]
    else
      value = block.call
      @cache[cache_key] = { value: value, cached_at: Time.now }
      value
    end
  end

  private

  def expired?(key)
    ttl = self.class.cache_config[:ttl]
    Time.now - @cache[key][:cached_at] > ttl
  end
end

# Usage:
class EventRepository
  include Cacheable

  configure_cache ttl: 300, enabled: true

  def expensive_query
    cached_fetch do
      # expensive operation
    end
  end
end
```

---

## Reflection Questions

After completing these exercises:

1. **When should you use a module vs a class?**
   - Module: Behavior/capability that multiple classes need
   - Class: Concrete thing that can be instantiated

2. **What's the difference between include and extend?**
   - include: Instance methods, goes in ancestors
   - extend: Class methods, goes in eigenclass

3. **When should you use prepend?**
   - When you want to wrap/decorate existing methods
   - When you need to run code before the class's method

4. **How do you test modules?**
   - Create a test class that includes the module
   - Test the module in isolation first
   - Then test integration with real classes

5. **What's the method lookup order?**
   - Class → Prepended modules → Included modules (last to first) → Superclass → Object → BasicObject

---

## Next Steps

1. ✅ Complete exercises 1-3 (core concepts)
2. ✅ Try exercises 4-5 (advanced patterns)
3. ✅ Refactor your Event and Venue to use modules
4. ✅ Run all tests (should pass with 100% coverage)
5. ✅ Ready for Day 4? Let me know!

**Remember:** Modules are one of Ruby's most powerful features. Master them and you'll write cleaner, more maintainable code!
