# frozen_string_literal: true

# Classes vs Modules Tutorial - Day 3
# Run: docker-compose run --rm app ruby lib/modules_tutorial.rb

puts '=' * 70
puts "Classes vs Modules - Understanding Ruby's Composition Model"
puts '=' * 70
puts

# ============================================================================
# CLASSES - Creating instances
# ============================================================================

puts '1. CLASSES - Blueprints for creating objects'
puts '-' * 70

class Dog
  def initialize(name)
    @name = name
  end

  def speak
    "#{@name} says Woof!"
  end
end

class Cat
  def initialize(name)
    @name = name
  end

  def speak
    "#{@name} says Meow!"
  end
end

fido = Dog.new('Fido')
whiskers = Cat.new('Whiskers')

puts fido.speak
puts whiskers.speak
puts

# OBSERVATION: Both classes have duplicate initialize code!
# This is a problem modules can solve.

# ============================================================================
# MODULES - Cannot be instantiated, used for namespacing and mixins
# ============================================================================

puts '2. MODULES - Two main uses'
puts '-' * 70

# USE CASE 1: NAMESPACING
# WHY? Avoid naming conflicts, organize related code
module Animals
  class Dog
    def speak
      'Woof'
    end
  end

  class Cat
    def speak
      'Meow'
    end
  end
end

module Vehicles
  # Different Dog!
  class Dog
    def speak
      'Beep beep' # Greyhound bus
    end
  end
end

animal_dog = Animals::Dog.new
vehicle_dog = Vehicles::Dog.new

puts "Animal dog: #{animal_dog.speak}"
puts "Vehicle dog: #{vehicle_dog.speak}"
puts

# USE CASE 2: MIXINS (Shared behavior)
# This is what we'll focus on today!

puts '3. MIXINS - Sharing behavior across classes'
puts '-' * 70

# Define a module with shared behavior
module Speakable
  def speak
    "#{@name} says #{sound}"
  end

  # This will be defined by the class that includes this module
  def sound
    raise NotImplementedError, 'Subclass must implement sound method'
  end
end

# Mix the module into classes
class Bird
  include Speakable # Mix in the Speakable behavior

  def initialize(name)
    @name = name
  end

  def sound
    'Chirp'
  end
end

class Cow
  include Speakable

  def initialize(name)
    @name = name
  end

  def sound
    'Moo'
  end
end

tweety = Bird.new('Tweety')
bessie = Cow.new('Bessie')

puts tweety.speak  # Uses Speakable module
puts bessie.speak  # Uses Speakable module
puts

# WHY this is powerful:
# - No code duplication
# - Each class only defines what's unique (sound)
# - Shared logic (speak) is in ONE place

# ============================================================================
# INCLUDE vs EXTEND vs PREPEND
# ============================================================================

puts '4. INCLUDE vs EXTEND vs PREPEND - The Three Ways to Mix'
puts '-' * 70

module Greetings
  def hello
    'Hello from Greetings'
  end

  def self.hi
    'Hi from Greetings (module method)'
  end
end

# INCLUDE - Adds methods as INSTANCE methods
class Person
  include Greetings
end

person = Person.new
puts "INCLUDE: #{person.hello}" # Works! Instance method
# puts Person.hello  # Error! Not a class method
puts

# EXTEND - Adds methods as CLASS methods
class Company
  extend Greetings
end

puts "EXTEND: #{Company.hello}" # Works! Class method
# company = Company.new
# puts company.hello  # Error! Not an instance method
puts

# PREPEND - Like include, but changes method lookup order
# We'll see this in detail with method lookup chain

# ============================================================================
# METHOD LOOKUP CHAIN (ancestors)
# ============================================================================

puts '5. METHOD LOOKUP CHAIN - How Ruby finds methods'
puts '-' * 70

module A
  def greet
    'From A'
  end
end

module B
  def greet
    'From B'
  end
end

class MyClass
  include A
  include B # B is included AFTER A

  def greet
    'From MyClass'
  end
end

obj = MyClass.new
puts "obj.greet: #{obj.greet}"
puts 'Method lookup chain (ancestors):'
puts MyClass.ancestors.inspect
puts

# EXPLANATION:
# Ruby searches for methods in this order:
# 1. The class itself (MyClass)
# 2. Last included module (B)
# 3. First included module (A)
# 4. Superclass (Object)
# 5. BasicObject

# ============================================================================
# PREPEND - Changes lookup order
# ============================================================================

puts '6. PREPEND - Insert module BEFORE the class'
puts '-' * 70

module Logger
  def save
    puts '  [LOG] Saving...'
    super # Call the next method in the chain
    puts '  [LOG] Saved!'
  end
end

class Document
  def save
    puts '  [CORE] Writing to disk...'
  end
end

class LoggedDocument < Document
  prepend Logger # Logger goes BEFORE LoggedDocument
end

doc = LoggedDocument.new
puts 'Calling doc.save:'
doc.save
puts
puts 'Lookup chain:'
puts LoggedDocument.ancestors.inspect
puts

# EXPLANATION:
# prepend puts Logger BEFORE LoggedDocument in the chain
# So Logger#save runs first, calls super, which goes to Document#save

# ============================================================================
# SUPER KEYWORD - Call next method in chain
# ============================================================================

puts '7. SUPER - Calling parent/module methods'
puts '-' * 70

module Validatable
  def save
    if valid?
      puts '  [Validatable] Validation passed'
      super # Call next method in chain
    else
      puts '  [Validatable] Validation failed!'
      false
    end
  end

  def valid?
    true # Override in class
  end
end

class Record
  def save
    puts '  [Record] Saving to database...'
    true
  end
end

class User < Record
  include Validatable

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def valid?
    !name.nil? && !name.empty?
  end
end

valid_user = User.new('Alice')
puts 'Saving valid user:'
valid_user.save
puts

invalid_user = User.new('')
puts 'Saving invalid user:'
invalid_user.save
puts

# ============================================================================
# PRACTICAL EXAMPLE - Your actual code!
# ============================================================================

puts '8. REAL EXAMPLE - Solving your code duplication'
puts '-' * 70

# BEFORE: Duplicated validation in Event and Venue
# Event has: validate name is 3-100 characters
# Venue has: validate name is 3-100 characters
# DUPLICATED CODE!

# AFTER: Extract to module
module NameValidatable
  def validate_name_length(name, min: 3, max: 100)
    if name.nil? || name.empty?
      raise ArgumentError, 'name is required'
    elsif name.length < min
      raise ArgumentError, "name must be at least #{min} characters long"
    elsif name.length > max
      raise ArgumentError, "name must be at most #{max} characters long"
    end
  end
end

class Event
  include NameValidatable

  attr_reader :name

  def initialize(name:)
    validate_name_length(name)  # Use module method!
    @name = name
  end
end

class Venue
  include NameValidatable

  attr_reader :name

  def initialize(name:)
    validate_name_length(name)  # Same module method!
    @name = name
  end
end

begin
  event = Event.new(name: 'RubyConf 2026')
  puts "✓ Created event: #{event.name}"
rescue ArgumentError => e
  puts "✗ Error: #{e.message}"
end

begin
  event = Event.new(name: 'AB') # Too short!
  puts "✓ Created event: #{event.name}"
rescue ArgumentError => e
  puts "✗ Error: #{e.message}"
end
puts

# ============================================================================
# KEY DIFFERENCES: Class vs Module
# ============================================================================

puts '9. CLASS vs MODULE - When to use which?'
puts '-' * 70

puts 'CLASS:'
puts '  - Can be instantiated (MyClass.new)'
puts '  - Can have instance variables (@name)'
puts '  - Can inherit from ONE superclass'
puts '  - Use for: Things you create (Event, User, Order)'
puts

puts 'MODULE:'
puts '  - CANNOT be instantiated'
puts '  - Used for namespacing and mixins'
puts '  - Can be included in MULTIPLE classes'
puts '  - Use for: Shared behavior (Searchable, Validatable)'
puts

puts 'WHEN TO USE WHAT:'
puts '  - Is it a THING? → Class (Event, User, Product)'
puts '  - Is it a BEHAVIOR? → Module (Searchable, Timestampable)'
puts '  - Is it a CATEGORY? → Module (Admin::Users, API::V1::Events)'
puts

# ============================================================================
# SUMMARY
# ============================================================================

puts '=' * 70
puts 'KEY TAKEAWAYS'
puts '=' * 70
puts
puts '1. Classes create objects, modules share behavior'
puts '2. include: Adds module methods as instance methods'
puts '3. extend: Adds module methods as class methods'
puts '4. prepend: Like include, but goes BEFORE class in lookup'
puts '5. super: Calls next method in the lookup chain'
puts '6. ancestors: Shows the method lookup order'
puts '7. Modules prevent code duplication'
puts
puts "NEXT: We'll create real modules for your ticketing system!"
puts '=' * 70
