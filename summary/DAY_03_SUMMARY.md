# Day 3 Summary: Classes, Modules & Mixins

## What We Built Today

✅ **Validatable** module - Shared validation logic  
✅ **Timestampable** module - Automatic timestamp tracking  
✅ Refactored Event and Venue to use modules  
✅ Understanding of include, extend, prepend  
✅ Method lookup chain (ancestors)

---

## The Problem We Solved

### BEFORE (Code Duplication):

```ruby
# In Event:
def validate_required_fields(name:)
  raise ArgumentError, 'name is required' if name.nil? || name.empty?
  raise ArgumentError, 'name must be at least 3 characters' if name.length < 3
  raise ArgumentError, 'name must be at most 100 characters' if name.length > 100
end

# In Venue:
def validate_required_fields(name:)
  raise ArgumentError, 'name is required' if name.nil? || name.empty?
  raise ArgumentError, 'name must be at least 3 characters' if name.length < 3
  raise ArgumentError, 'name must be at most 100 characters' if name.length > 100
end
```

**Problem:** Same validation logic duplicated in two classes!

### AFTER (With Modules):

```ruby
# Create module once:
module Validatable
  def validate_name(name, min: 3, max: 100)
    # validation logic here
  end
end

# Use in both classes:
class Event
  include Validatable

  def validate_required_fields(name:)
    validate_name(name)  # From module!
  end
end

class Venue
  include Validatable

  def validate_required_fields(name:)
    validate_name(name)  # Same module method!
  end
end
```

**Solution:** Shared logic in ONE place, used by many classes!

---

## Key Concepts Learned

### 1. **Class vs Module**

| Class                       | Module                           |
| --------------------------- | -------------------------------- |
| Can be instantiated         | CANNOT be instantiated           |
| `event = Event.new`         | `❌ Validatable.new`             |
| Single inheritance          | Multiple mixins                  |
| Represents a THING          | Represents BEHAVIOR              |
| Use for: Event, User, Order | Use for: Validatable, Searchable |

**When to use:**

- **Class**: It's a noun (Event, User, Product)
- **Module**: It's an adjective or capability (Validatable, Searchable, Comparable)

### 2. **Include - Instance Methods**

```ruby
module Greeter
  def hello
    'Hello!'
  end
end

class Person
  include Greeter
end

person = Person.new
person.hello  # => "Hello!" (instance method)
```

**How it works:**

- Adds module methods as **instance methods**
- Module goes into **ancestors chain**
- Can call `super` to chain methods

**Use when:** You want behavior on instances

### 3. **Extend - Class Methods**

```ruby
module Greeter
  def hello
    'Hello!'
  end
end

class Company
  extend Greeter
end

Company.hello  # => "Hello!" (class method)
```

**How it works:**

- Adds module methods as **class methods**
- Module NOT in ancestors chain
- Used for class-level behavior

**Use when:** You want behavior on the class itself

### 4. **Prepend - Before Class in Lookup**

```ruby
module Logger
  def save
    puts "Before save"
    super  # Call next in chain
    puts "After save"
  end
end

class Document
  def save
    puts "Saving..."
  end
end

class LoggedDocument < Document
  prepend Logger  # Logger goes BEFORE LoggedDocument
end

doc = LoggedDocument.new
doc.save
# Output:
# Before save
# Saving...
# After save
```

**How it works:**

- Inserts module **before** the class in lookup
- Perfect for wrapping/decorating behavior
- Common for logging, caching, validation

**Use when:** You want to wrap existing methods

### 5. **Method Lookup Chain (ancestors)**

When you call `event.some_method`, Ruby searches in this order:

```ruby
class Event
  include Validatable
  include Timestampable
end

Event.ancestors
# => [Event, Timestampable, Validatable, Object, Kernel, BasicObject]
```

**Search order:**

1. **Event** class itself
2. **Timestampable** (last included)
3. **Validatable** (first included)
4. **Object** (superclass)
5. **Kernel** (module included in Object)
6. **BasicObject** (root class)

**Last included is searched first!**

### 6. **Super Keyword**

Calls the next method in the ancestors chain:

```ruby
module Validatable
  def save
    validate!
    super  # Calls next save method in chain
  end
end

class Event
  include Validatable

  def save
    write_to_db
  end
end

event.save
# 1. Validatable#save runs
# 2. Calls super
# 3. Event#save runs
```

**Three forms of super:**

- `super` - passes all arguments to next method
- `super()` - passes NO arguments
- `super(arg1, arg2)` - passes specific arguments

---

## Modules We Created

### Validatable Module

**Purpose:** Share validation logic across classes

**Methods provided:**

```ruby
validate_name(name, min: 3, max: 100)
validate_presence(value, field_name: 'field')
validate_length(value, min:, max:, field_name: 'field')
validate_positive(value, field_name: 'field')
validate_range(value, min:, max:, field_name: 'field')
validate_time_order(start_time, end_time)
```

**Usage:**

```ruby
class Event
  include Validatable

  def initialize(name:, total_seats:)
    validate_name(name)
    validate_positive(total_seats, field_name: 'total_seats')
  end
end
```

**Benefits:**

- No code duplication
- Consistent validation logic
- Test module once, use everywhere
- Easy to add new validation methods

### Timestampable Module

**Purpose:** Automatic timestamp tracking

**Methods provided:**

```ruby
set_timestamps         # Initialize created_at and updated_at
touch                  # Update updated_at to current time
new_record?           # Check if timestamps are not set
modified?             # Check if updated_at > created_at
age                   # Seconds since creation
```

**Attributes provided:**

```ruby
created_at            # When object was created
updated_at            # When object was last modified
```

**Usage:**

```ruby
class Event
  include Timestampable

  def initialize(name:)
    @name = name
    set_timestamps  # Call in initialize
  end

  def update_name(new_name)
    @name = new_name
    touch  # Update timestamp
  end
end

event = Event.new(name: 'RubyConf')
event.created_at  # => 2026-05-02 10:30:00
event.new_record?  # => false

sleep(1)
event.update_name('RubyConf 2026')
event.updated_at   # => 2026-05-02 10:30:01
event.modified?    # => true
```

---

## Design Patterns Learned

### Mixin Pattern

**Definition:** Including modules to add behavior to classes

**Benefits:**

- **Composition over inheritance** - Mix multiple behaviors
- **DRY principle** - Share code without duplication
- **Single Responsibility** - Each module does ONE thing
- **Testability** - Test modules independently

**Example:**

```ruby
class Event
  include Validatable    # Validation behavior
  include Timestampable  # Timestamp behavior
  include Searchable     # Search behavior (coming soon!)
end
```

### Decorator Pattern (with prepend)

**Definition:** Wrapping methods to add behavior

```ruby
module Cache
  def fetch_data
    @cached ||= super  # Call original, cache result
  end
end

class Repository
  prepend Cache  # Wrap fetch_data

  def fetch_data
    # expensive database query
  end
end
```

---

## Ruby Idioms & Best Practices

### 1. **Module Naming**

```ruby
# Good - Adjectives or "able"
module Validatable    # Can be validated
module Searchable     # Can be searched
module Timestampable  # Can be timestamped
module Comparable     # Can be compared

# Good - Behavior descriptions
module Logger
module Authenticator
module Serializer

# Avoid - Nouns (use classes instead)
module User    # Should be a class
module Event   # Should be a class
```

### 2. **When to Include vs Extend**

```ruby
# Include - for instance behavior
class User
  include Authenticatable  # user.authenticate
end

# Extend - for class behavior
class User
  extend Findable  # User.find_by_email
end
```

### 3. **Module Organization**

```ruby
# One module per file
# lib/validatable.rb
module Validatable
  # ...
end

# Require where needed
require_relative 'validatable'

class Event
  include Validatable
end
```

### 4. **Testing Modules**

```ruby
# Test module in isolation
RSpec.describe Validatable do
  let(:test_class) do
    Class.new do
      include Validatable
    end
  end

  subject(:validator) { test_class.new }

  it 'validates names' do
    expect { validator.validate_name('Test') }.not_to raise_error
  end
end
```

---

## Common Patterns Comparison

### Inheritance vs Modules

```ruby
# INHERITANCE (single, rigid)
class Animal
  def speak
    "Sound"
  end
end

class Dog < Animal
  def speak
    "Woof"
  end
end

# Can only inherit from ONE class
# Tight coupling
# Changes to Animal affect all subclasses

# MODULES (multiple, flexible)
module Speakable
  def speak
    "Sound"
  end
end

module Walkable
  def walk
    "Walking"
  end
end

class Dog
  include Speakable
  include Walkable
end

# Can include MANY modules
# Loose coupling
# Each module is independent
```

**Rule of thumb:** Use inheritance for IS-A relationships, modules for HAS-A capabilities.

---

## Before and After Comparison

### Event Class Evolution

**Day 1 (No modules):**

```ruby
class Event
  def initialize(name:)
    raise ArgumentError, 'name is required' if name.nil?
    raise ArgumentError, 'name too short' if name.length < 3
    @name = name
  end
end
```

**Day 3 (With modules):**

```ruby
class Event
  include Validatable
  include Timestampable

  def initialize(name:)
    validate_name(name)
    @name = name
    set_timestamps
  end
end
```

**Improvements:**

- Less code in Event class
- Validation logic reusable
- Automatic timestamp tracking
- Easier to test
- Easier to maintain

---

## Method Lookup Examples

### Example 1: Simple Include

```ruby
module A
  def test
    "From A"
  end
end

class MyClass
  include A
end

MyClass.ancestors
# => [MyClass, A, Object, Kernel, BasicObject]

obj = MyClass.new
obj.test  # Searches: MyClass -> A (found!)
```

### Example 2: Multiple Includes

```ruby
module A
  def test
    "From A"
  end
end

module B
  def test
    "From B"
  end
end

class MyClass
  include A
  include B  # Last included
end

MyClass.ancestors
# => [MyClass, B, A, Object, Kernel, BasicObject]

obj = MyClass.new
obj.test  # => "From B" (B is searched before A)
```

### Example 3: Prepend

```ruby
module Logger
  def save
    puts "Logging..."
    super
  end
end

class Document
  def save
    puts "Saving..."
  end
end

class LoggedDocument < Document
  prepend Logger
end

LoggedDocument.ancestors
# => [Logger, LoggedDocument, Document, Object, ...]

doc = LoggedDocument.new
doc.save
# Output:
# Logging...
# Saving...
```

---

## Practical Applications

### Where Modules Are Used in Rails

**ActiveRecord::Callbacks**

```ruby
class User < ApplicationRecord
  include ActiveRecord::Callbacks

  before_save :normalize_email
end
```

**ActiveModel::Validations**

```ruby
class User
  include ActiveModel::Validations

  validates :email, presence: true
end
```

**Enumerable** (built-in Ruby)

```ruby
class EventCollection
  include Enumerable

  def each(&block)
    @events.each(&block)
  end
end
```

---

## Looking Back

### Day 1: Single Event class

### Day 2: Collection of Events with querying

### Day 3: Shared behavior with modules ← YOU ARE HERE

**How they connect:**

```ruby
# Day 1: Create event
event = Event.new(name: 'RubyConf')

# Day 2: Store and query
repo = EventRepository.new([event])

# Day 3: Shared validation and timestamps
# Event and Venue both use Validatable
# Both track created_at/updated_at
```

---

## Looking Ahead to Day 4

Tomorrow: **Error Handling & Contract Design**

**Topics:**

- Custom exception classes
- Error boundaries
- Result objects (Success/Failure)
- Railway-oriented programming
- Null object pattern

**We'll build:**

- Custom exception hierarchy
- BookingResult class (Success/Failure)
- Proper error propagation
- User-friendly error messages

**Why it matters:**
Robust error handling is critical for production systems.
You'll learn how to handle failures gracefully.

---

## Exercises to Reinforce Learning

See `DAY_3_EXERCISES.md` for hands-on practice:

1. Create Searchable module for EventRepository
2. Add Comparable to Event (sort by date)
3. Create Loggable module with prepend
4. Implement SoftDeletable module
5. Build Serializable module (to_json)

---

## Key Takeaways

1. ✅ **Modules share behavior** - Use for common functionality
2. ✅ **Include for instance methods** - Adds to ancestors chain
3. ✅ **Extend for class methods** - Adds to eigenclass
4. ✅ **Prepend for wrapping** - Goes before class in lookup
5. ✅ **Composition > Inheritance** - More flexible, less coupling
6. ✅ **Test modules independently** - Create test class
7. ✅ **One concern per module** - Single Responsibility Principle

---

## Commands Reference

```bash
# Run modules tutorial
docker-compose run --rm app ruby lib/modules_tutorial.rb

# Run method lookup demo
docker-compose run --rm app ruby method_lookup_demo.rb

# Run Comparable example
docker-compose run --rm app ruby lib/comparable_example.rb

# Run tests
docker-compose run --rm app bundle exec rspec

# Run specific module tests
docker-compose run --rm app bundle exec rspec spec/validatable_spec.rb
docker-compose run --rm app bundle exec rspec spec/timestampable_spec.rb
```

---

## Resources for Deeper Learning

- **Ruby Modules**: https://ruby-doc.org/core/Module.html
- **Method Lookup**: https://www.rubyguides.com/2019/04/ruby-module-include/
- **Comparable Module**: https://ruby-doc.org/core/Comparable.html
- **Composition vs Inheritance**: https://thoughtbot.com/blog/reusable-oo-composition

---

**Excellent work on Day 3! 🎉**

You now understand Ruby's composition model - one of the most important concepts for writing idiomatic Ruby. Modules are everywhere in Ruby and Rails!

Ready for Day 4? Let me know!
