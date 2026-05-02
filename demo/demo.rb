#!/usr/bin/env ruby
# frozen_string_literal: true

# This script demonstrates running our Event class
# In real TDD workflow:
# 1. Write test (RED)
# 2. Run: bundle exec rspec (see it fail)
# 3. Implement code (GREEN)
# 4. Run: bundle exec rspec (see it pass)
# 5. Refactor and repeat

require_relative 'lib/event'

puts '=' * 60
puts 'Event Class Demonstration'
puts '=' * 60
puts

# Create a valid event
puts 'Creating a valid event...'
event = Event.new(
  name: 'RubyConf 2026',
  description: 'The premier Ruby conference',
  venue: 'San Francisco Convention Center',
  start_time: Time.new(2026, 6, 15, 9, 0, 0),
  end_time: Time.new(2026, 6, 17, 18, 0, 0),
  total_seats: 500
)

puts '✓ Event created successfully!'
puts event
puts "  Duration: #{event.duration_in_hours} hours"
puts "  Available seats: #{event.available_seats}/#{event.total_seats}"
puts

# Demonstrate validation: missing name
puts 'Attempting to create event without name...'
begin
  Event.new(
    description: 'Description',
    venue: 'Venue',
    start_time: Time.now,
    end_time: Time.now + 3600,
    total_seats: 100
  )
  puts '✗ Should have raised error!'
rescue ArgumentError => e
  puts "✓ Correctly raised: #{e.message}"
end
puts

# Demonstrate validation: invalid time range
puts 'Attempting to create event with end_time before start_time...'
begin
  start_time = Time.now
  Event.new(
    name: 'Bad Event',
    description: 'Description',
    venue: 'Venue',
    start_time: start_time,
    end_time: start_time - 3600,
    total_seats: 100
  )
  puts '✗ Should have raised error!'
rescue ArgumentError => e
  puts "✓ Correctly raised: #{e.message}"
end
puts

# Demonstrate validation: invalid seat count
puts 'Attempting to create event with 0 seats...'
begin
  Event.new(
    name: 'Event',
    description: 'Description',
    venue: 'Venue',
    start_time: Time.now,
    end_time: Time.now + 3600,
    total_seats: 0
  )
  puts '✗ Should have raised error!'
rescue ArgumentError => e
  puts "✓ Correctly raised: #{e.message}"
end
puts

puts '=' * 60
puts 'All validations working correctly!'
puts '=' * 60
puts
puts 'Next steps:'
puts '1. Run tests: bundle exec rspec'
puts '2. Check coverage: open coverage/index.html'
puts '3. Run linter: bundle exec rubocop'
