#!/usr/bin/env ruby
# frozen_string_literal: true

# VALUE OBJECTS & FORM OBJECTS TUTORIAL
# Run this: docker compose run --rm app ruby lib/value_objects_tutorial.rb

puts <<~HEADER
  ================================================================================
  VALUE OBJECTS & FORM OBJECTS TUTORIAL
  ================================================================================

  This tutorial demonstrates the concepts covered in Day 5:
  1. What is primitive obsession?
  2. Value object characteristics
  3. Why immutability matters
  4. Form objects for validation

  Press ENTER to continue through examples...
  ================================================================================
HEADER

def pause
  print "\n▶ Press ENTER to continue..."
  gets
  puts "\n"
end

# ==============================================================================
# PART 1: The Problem - Primitive Obsession
# ==============================================================================

puts '=' * 80
puts 'PART 1: THE PROBLEM - PRIMITIVE OBSESSION'
puts '=' * 80

puts <<~PROBLEM
  PROBLEM: Using basic types (integers, strings) for domain concepts

  Example - Representing money with integers:
PROBLEM

# Bad: Primitive obsession
ticket_price = 100
vip_price = 200
currency = 'USD'

puts "  ticket_price = #{ticket_price}"
puts "  vip_price = #{vip_price}"
puts "  currency = '#{currency}'"

puts "\n❌ PROBLEMS:"
puts '  1. What if we mix currencies?'

usd_price = 100
eur_price = 100
total = usd_price + eur_price # BUG! Can't add different currencies
puts "     total = usd_price + eur_price  # => #{total} (WRONG! Mixed currencies)"

puts "\n  2. Currency is separate - easy to forget/misuse"
puts '     price_without_currency = 100  # Which currency??'

puts "\n  3. No validation"
negative_price = -50
puts "     negative_price = #{negative_price}  # Should this be allowed?"

puts "\n  4. No encapsulation of domain rules"
puts '     How to apply tax? Discounts? Formatting?'

pause

# ==============================================================================
# PART 2: Value Objects to the Rescue
# ==============================================================================

puts '=' * 80
puts 'PART 2: VALUE OBJECTS - THE SOLUTION'
puts '=' * 80

# Now with value objects
require 'date'

class Money
  attr_reader :amount, :currency

  def initialize(amount, currency = 'USD')
    raise ArgumentError, 'Amount must be positive' unless amount.positive?

    @amount = amount
    @currency = currency
    freeze
  end

  def ==(other)
    amount == other.amount && currency == other.currency
  end

  def +(other)
    raise ArgumentError, "Currency mismatch: #{currency} vs #{other.currency}" unless currency == other.currency

    Money.new(amount + other.amount, currency)
  end

  def *(other)
    Money.new(amount * other, currency)
  end

  def to_s
    format('%.2f %s', amount, currency)
  end
end

puts '✅ WITH VALUE OBJECT:'
puts

usd1 = Money.new(100, 'USD')
usd2 = Money.new(50, 'USD')
puts "  usd1 = Money.new(100, 'USD')  # => #{usd1}"
puts "  usd2 = Money.new(50, 'USD')   # => #{usd2}"

total = usd1 + usd2
puts "\n  total = usd1 + usd2  # => #{total} ✓ Safe!"

puts "\n  Currency mismatch prevented:"
begin
  eur = Money.new(100, 'EUR')
  usd1 + eur
rescue ArgumentError => e
  puts "    usd1 + eur  # => ArgumentError: #{e.message} ✓"
end

puts "\n  Negative amounts prevented:"
begin
  Money.new(-100, 'USD')
rescue ArgumentError => e
  puts "    Money.new(-100, 'USD')  # => ArgumentError: #{e.message} ✓"
end

pause

# ==============================================================================
# PART 3: Immutability
# ==============================================================================

puts '=' * 80
puts 'PART 3: WHY IMMUTABILITY MATTERS'
puts '=' * 80

puts 'VALUE OBJECTS ARE FROZEN:'
puts

price = Money.new(100, 'USD')
puts "  price = Money.new(100, 'USD')"
puts "  price.frozen?  # => #{price.frozen?}"

puts "\n  Can't modify:"
begin
  price.instance_variable_set(:@amount, 200)
rescue RuntimeError
  puts '    price.amount = 200  # => FrozenError ✓'
end

puts "\n  Methods return NEW instances:"
double_price = price * 2
puts '    double_price = price * 2'
puts "    price         # => #{price} (unchanged)"
puts "    double_price  # => #{double_price} (new object)"
puts "    price.equal?(double_price)  # => #{price.equal?(double_price)}"

puts "\nBENEFITS:"
puts '  1. Thread-safe - no concurrent modification'
puts '  2. Predictable - no spooky action at a distance'
puts '  3. Can use as hash keys'

hash = {}
hash[Money.new(100, 'USD')] = 'coffee price'
puts "\n    hash[Money.new(100, 'USD')] = 'coffee price'"
puts "    hash[Money.new(100, 'USD')]  # => '#{hash[Money.new(100, 'USD')]}' ✓"

pause

# ==============================================================================
# PART 4: Value Equality vs Identity Equality
# ==============================================================================

puts '=' * 80
puts 'PART 4: VALUE EQUALITY VS IDENTITY'
puts '=' * 80

puts 'PRIMITIVE TYPES:'
puts

a = 'hello'
b = 'hello'
puts "  a = 'hello'"
puts "  b = 'hello'"
puts "  a == b        # => #{a == b} (value equality)"
puts "  a.equal?(b)   # => #{a.equal?(b)} (different objects)"

puts "\nVALUE OBJECTS WORK THE SAME WAY:"
puts

m1 = Money.new(100, 'USD')
m2 = Money.new(100, 'USD')
puts "  m1 = Money.new(100, 'USD')"
puts "  m2 = Money.new(100, 'USD')"
puts "  m1 == m2      # => #{m1 == m2} (value equality ✓)"
puts "  m1.equal?(m2) # => #{m1.equal?(m2)} (different objects)"

puts "\nWHY THIS MATTERS:"
puts '  - Can compare based on business value'
puts "  - Don't care about object identity"
puts "  - #{Money.new(100, 'USD')} is the same as #{Money.new(100, 'USD')}"

pause

# ==============================================================================
# PART 5: DateRange Example
# ==============================================================================

puts '=' * 80
puts 'PART 5: DATERANGE VALUE OBJECT'
puts '=' * 80

class DateRange
  attr_reader :start_date, :end_date

  def initialize(start_date, end_date)
    raise ArgumentError if start_date > end_date

    @start_date = start_date
    @end_date = end_date
    freeze
  end

  def days
    (end_date - start_date).to_i + 1
  end

  def includes?(date)
    date.between?(start_date, end_date)
  end

  def overlaps?(other)
    start_date <= other.end_date && end_date >= other.start_date
  end

  def to_s
    "#{start_date} to #{end_date}"
  end
end

puts 'ENCAPSULATING DATE LOGIC:'
puts

range = DateRange.new(Date.new(2024, 6, 1), Date.new(2024, 6, 7))
puts '  range = DateRange.new(Date.new(2024, 6, 1), Date.new(2024, 6, 7))'
puts "  range  # => #{range}"
puts "  range.days  # => #{range.days}"

check_date = Date.new(2024, 6, 5)
puts "\n  check_date = Date.new(2024, 6, 5)"
puts "  range.includes?(check_date)  # => #{range.includes?(check_date)}"

other = DateRange.new(Date.new(2024, 6, 6), Date.new(2024, 6, 10))
puts "\n  other = DateRange.new(Date.new(2024, 6, 6), Date.new(2024, 6, 10))"
puts "  range.overlaps?(other)  # => #{range.overlaps?(other)}"

puts "\nWITHOUT VALUE OBJECT (primitive obsession):"
puts '  # Need two separate dates everywhere'
puts '  start_date = Date.new(2024, 6, 1)'
puts '  end_date = Date.new(2024, 6, 7)'
puts '  # Manual calculations everywhere:'
puts '  days = (end_date - start_date).to_i + 1'
puts '  includes = check_date >= start_date && check_date <= end_date'
puts '  # Repeated logic, easy to make mistakes!'

pause

# ==============================================================================
# PART 6: Form Objects
# ==============================================================================

puts '=' * 80
puts 'PART 6: FORM OBJECTS - SEPARATING VALIDATION'
puts '=' * 80

puts 'THE PROBLEM: Business logic handling raw input'
puts

puts '  # Controller receives raw params:'
puts "  params = { seats: 'abc', email: 'bad' }"
puts
puts '  # Business service gets garbage:'
puts '  BookingService.book(params[:seats])  # BOOM! 💥'

pause

puts "\nTHE SOLUTION: Form Object validates first"
puts

class SimpleForm
  attr_reader :seats, :email, :errors

  def initialize(params)
    @seats = params[:seats]
    @email = params[:email]
    @errors = {}
  end

  def valid?
    @errors = {}

    @errors[:seats] = ['must be a number'] unless numeric?(seats)

    @errors[:email] = ['must be valid'] unless email&.include?('@')

    @errors.empty?
  end

  def to_h
    { seats: seats.to_i, email: email }
  end

  private

  def numeric?(value)
    true if Integer(value)
  rescue ArgumentError, TypeError
    false
  end
end

puts "  form = SimpleForm.new(seats: 'abc', email: 'bad')"
form = SimpleForm.new(seats: 'abc', email: 'bad')

puts "  form.valid?  # => #{form.valid?}"
puts "  form.errors  # => #{form.errors}"

puts "\n  Valid form:"
valid_form = SimpleForm.new(seats: '3', email: 'user@example.com')
puts "  valid_form = SimpleForm.new(seats: '3', email: 'user@example.com')"
puts "  valid_form.valid?  # => #{valid_form.valid?}"
puts "  valid_form.to_h    # => #{valid_form.to_h}"
puts '                      # ^ Notice: "3" → 3 (coerced to integer)'

puts "\nWORKFLOW:"
puts '  1. Form receives raw params (strings, nils)'
puts '  2. Form validates (type checks, presence, format)'
puts '  3. Form coerces (strings → integers, symbols)'
puts '  4. Business service receives clean data'

pause

# ==============================================================================
# SUMMARY
# ==============================================================================

puts '=' * 80
puts 'SUMMARY: VALUE OBJECTS & FORM OBJECTS'
puts '=' * 80

puts <<~SUMMARY
  VALUE OBJECTS:
    ✓ Prevent primitive obsession
    ✓ Encapsulate domain rules
    ✓ Immutable (frozen)
    ✓ Value equality (not identity)
    ✓ Can use as hash keys
    ✓ Return new instances from operations

  Examples:
    - Money (amount + currency)
    - DateRange (start + end + domain ops)
    - Address (street + city + state + zip)
    - Percentage (value + formatting)

  FORM OBJECTS:
    ✓ Validate raw user input
    ✓ Coerce types (strings → proper types)
    ✓ Separate from business logic
    ✓ Don't persist to database
    ✓ User-friendly error messages

  Examples:
    - BookingForm
    - EventForm
    - RegistrationForm

  KEY PRINCIPLE:
    Make invalid states UNREPRESENTABLE
    - Money can't have negative amounts
    - DateRange can't have start > end
    - Form validation prevents bad data reaching business logic

  NEXT STEPS:
    1. Complete exercises in DAY_5_EXERCISES.md
    2. Run: docker compose run --rm app ruby day_5_demo.rb
    3. Tomorrow: Big refactoring + clean project structure!
SUMMARY

puts '=' * 80
puts 'END OF TUTORIAL'
puts '=' * 80
