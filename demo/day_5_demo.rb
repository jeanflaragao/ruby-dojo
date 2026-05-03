#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require_relative '../lib/value_objects/money'
require_relative '../lib/value_objects/date_range'
require_relative '../lib/models/ticket_type'
require_relative '../lib/forms/booking_form'

puts '=' * 80
puts 'DAY 5 DEMO: VALUE OBJECTS & FORM OBJECTS'
puts '=' * 80
puts

# ==============================================================================
# PART 1: Money Value Object - No More Primitive Obsession!
# ==============================================================================
puts '1. MONEY VALUE OBJECT'
puts '-' * 80

base_price = Money.new(50, 'USD')
puts "Base ticket price: #{base_price}"

# Arithmetic creates new instances (immutability)
bulk_price = base_price * 5
puts "5 tickets: #{bulk_price}"

# Value equality
price1 = Money.new(100, 'USD')
price2 = Money.new(100, 'USD')
puts "\n#{price1} == #{price2}? #{price1 == price2}"
puts "Same object? #{price1.equal?(price2)} (no - different instances)"

# Can't modify (frozen)
puts "\nFrozen (immutable)? #{base_price.frozen?}"

# Currency safety
begin
  usd = Money.new(100, 'USD')
  eur = Money.new(100, 'EUR')
  usd + eur
rescue ArgumentError => e
  puts "\n❌ Currency mismatch caught: #{e.message}"
end

puts

# ==============================================================================
# PART 2: DateRange Value Object - Domain-Specific Date Logic
# ==============================================================================
puts '2. DATERANGE VALUE OBJECT'
puts '-' * 80

conference_dates = DateRange.new(Date.new(2024, 6, 1), Date.new(2024, 6, 3))
puts "Conference: #{conference_dates}"
puts "Duration: #{conference_dates.days} days (#{conference_dates.weeks} weeks)"

# Check specific date
check_date = Date.new(2024, 6, 2)
puts "\nDoes #{check_date} fall in conference? #{conference_dates.includes?(check_date)}"

# Check overlap with another event
workshop_dates = DateRange.new(Date.new(2024, 6, 3), Date.new(2024, 6, 5))
puts "\nWorkshop: #{workshop_dates}"
puts "Overlaps with conference? #{conference_dates.overlaps?(workshop_dates)}"

# No overlap
concert_dates = DateRange.new(Date.new(2024, 6, 10), Date.new(2024, 6, 12))
puts "\nConcert: #{concert_dates}"
puts "Overlaps with conference? #{conference_dates.overlaps?(concert_dates)}"

puts

# ==============================================================================
# PART 3: TicketType Hierarchy - Polymorphism in Action
# ==============================================================================
puts '3. TICKET TYPE HIERARCHY'
puts '-' * 80

base = Money.new(100, 'USD')
puts "Base price: #{base}\n\n"

# Create different ticket types
vip = VIPTicket.new(base)
general = GeneralTicket.new(base)
student = StudentTicket.new(base)

tickets = [vip, general, student]

# Polymorphic behavior
tickets.each do |ticket|
  puts "#{ticket.tier.to_s.upcase} Ticket"
  puts "  Price: #{ticket.price}"
  puts "  Perks: #{ticket.perks.join(', ')}"
  puts "  Requires verification? #{ticket.requires_verification?}"
  puts
end

# Calculate revenue for different scenarios
puts 'Revenue Calculation:'
scenarios = [
  { type: vip, quantity: 10, name: 'VIP' },
  { type: general, quantity: 100, name: 'General' },
  { type: student, quantity: 50, name: 'Student' }
]

total_revenue = Money.new(0, 'USD')
scenarios.each do |scenario|
  revenue = scenario[:type].price * scenario[:quantity]
  total_revenue += revenue
  puts "  #{scenario[:quantity]} #{scenario[:name]} tickets: #{revenue}"
end
puts "  TOTAL: #{total_revenue}"

puts

# ==============================================================================
# PART 4: BookingForm - Form Validation Before Business Logic
# ==============================================================================
puts '4. BOOKING FORM VALIDATION'
puts '-' * 80

# Valid form
puts 'Valid booking:'
valid_form = BookingForm.new(
  event_name: 'Ruby Conference 2024',
  seats: '3',
  ticket_type: 'vip',
  email: 'alice@example.com'
)

if valid_form.valid?
  puts '  ✅ Form is valid!'
  puts "  Coerced data: #{valid_form.to_h}"
else
  puts '  ❌ Validation failed'
  valid_form.error_messages.each { |msg| puts "    - #{msg}" }
end

puts "\nInvalid forms:"

# Invalid: Bad seat count
invalid_seats = BookingForm.new(
  event_name: 'Concert',
  seats: 'abc',
  ticket_type: 'general',
  email: 'bob@example.com'
)

puts "\n  Seats = 'abc':"
if invalid_seats.valid?
  puts '    ✅ Valid'
else
  puts '    ❌ Errors:'
  invalid_seats.error_messages.each { |msg| puts "      - #{msg}" }
end

# Invalid: Too many seats
too_many = BookingForm.new(
  event_name: 'Festival',
  seats: '15',
  ticket_type: 'general',
  email: 'charlie@example.com'
)

puts "\n  Seats = 15 (max is 10):"
if too_many.valid?
  puts '    ✅ Valid'
else
  puts '    ❌ Errors:'
  too_many.error_messages.each { |msg| puts "      - #{msg}" }
end

# Invalid: Multiple errors
multiple_errors = BookingForm.new(
  seats: '-5',
  ticket_type: 'premium',
  email: 'not-an-email'
)

puts "\n  Multiple validation errors:"
if multiple_errors.valid?
  puts '    ✅ Valid'
else
  puts '    ❌ Errors:'
  multiple_errors.error_messages.each { |msg| puts "      - #{msg}" }
end

puts "\n#{'=' * 80}"
puts 'KEY TAKEAWAYS'
puts '=' * 80
puts <<~TAKEAWAYS
  1. VALUE OBJECTS prevent primitive obsession
     - Money instead of integers
     - DateRange instead of two dates
     - Domain rules encapsulated in the object

  2. VALUE OBJECTS are IMMUTABLE
     - Frozen after creation
     - Methods return new instances
     - Safe to use as hash keys

  3. EQUALITY by VALUE, not identity
     - Money.new(100, 'USD') == Money.new(100, 'USD') → true
     - Same values = equal, even if different objects

  4. FORM OBJECTS separate concerns
     - Validate raw input
     - Coerce types (strings → integers/symbols)
     - Keep business logic clean

  5. INHERITANCE is OK for value types
     - TicketType hierarchy makes sense
     - All tickets share same interface
     - Different behavior through polymorphism
TAKEAWAYS

puts "\nNext: Update BookingService to use Money, TicketType, and BookingForm!"
