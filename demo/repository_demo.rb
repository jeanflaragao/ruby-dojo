#!/usr/bin/env ruby
# frozen_string_literal: true

# EventRepository Demo - Day 2
# Run: docker-compose run --rm app ruby repository_demo.rb

require_relative '../lib/event'
require_relative '../lib/venue'
require_relative '../lib/event_repository'

puts '=' * 80
puts 'EventRepository Demonstration - Enumerable in Action!'
puts '=' * 80
puts

# Create sample events
puts 'Creating sample events...'
events = [
  Event.new(
    name: 'RubyConf 2026',
    description: 'The premier Ruby conference',
    venue: Venue.new(name: 'San Francisco Convention Center', address: '123 Main St, San Francisco, CA', capacity: 500),
    start_time: Time.new(2026, 6, 15, 9, 0, 0),
    end_time: Time.new(2026, 6, 17, 18, 0, 0),
    total_seats: 500
  ),
  Event.new(
    name: 'Rails Workshop',
    description: 'Hands-on Rails training',
    venue: Venue.new(name: 'New York Training Center', address: '456 Broadway, New York, NY', capacity: 30),
    start_time: Time.new(2026, 7, 10, 9, 0, 0),
    end_time: Time.new(2026, 7, 10, 17, 0, 0),
    total_seats: 30
  ),
  Event.new(
    name: 'Ruby Meetup SF',
    description: 'Monthly Ruby developers meetup',
    venue: Venue.new(name: 'San Francisco Coffee Shop', address: '789 Market St, San Francisco, CA', capacity: 50),
    start_time: Time.new(2026, 8, 5, 18, 0, 0),
    end_time: Time.new(2026, 8, 5, 20, 0, 0),
    total_seats: 50
  ),
  Event.new(
    name: 'React Summit',
    description: 'React and frontend technologies',
    venue: Venue.new(name: 'San Francisco Tech Hub', address: '101 Tech Blvd, San Francisco, CA', capacity: 300),
    start_time: Time.new(2026, 9, 20, 9, 0, 0),
    end_time: Time.new(2026, 9, 22, 18, 0, 0),
    total_seats: 300
  )
]

# Initialize repository
repo = EventRepository.new(events)
puts "✓ Created repository with #{repo.count} events"
puts

# ============================================================================
# BASIC OPERATIONS
# ============================================================================

puts '-' * 80
puts '1. BASIC OPERATIONS'
puts '-' * 80

puts "\nAll events:"
repo.all.each do |event|
  puts "  - #{event.name} (#{event.venue})"
end

puts "\nAdding a new event..."
new_event = Event.new(
  name: 'JavaScript Conference',
  description: 'Modern JavaScript',
  venue: Venue.new(name: 'San Francisco Tech Hub', address: '101 Tech Blvd, San Francisco, CA', capacity: 400),
  start_time: Time.new(2026, 10, 15, 9, 0, 0),
  end_time: Time.new(2026, 10, 17, 18, 0, 0),
  total_seats: 400
)
repo.add(new_event)
puts "✓ Repository now has #{repo.count} events"
puts

# ============================================================================
# SEARCHING AND FILTERING
# ============================================================================

puts '-' * 80
puts '2. SEARCHING AND FILTERING'
puts '-' * 80

# Find by exact name
puts "\nFinding 'RubyConf 2026' by exact name:"
found = repo.find_by_name('RubyConf 2026')
if found
  puts "  ✓ Found: #{found.name} at #{found.venue.name}"
else
  puts '  ✗ Not found'
end

# Search by partial name
puts "\nSearching for events with 'Ruby' in the name:"
ruby_events = repo.search_by_name('Ruby')
ruby_events.each do |event|
  puts "  - #{event.name}"
end
puts "  (Found #{ruby_events.size} events)"

# Filter by venue
puts "\nFiltering events in San Francisco:"
sf_events = repo.filter_by_venue('San Francisco')
sf_events.each do |event|
  puts "  - #{event.name} at #{event.venue}"
end
puts "  (Found #{sf_events.size} events)"

# Filter by date range
puts "\nEvents in July-August 2026:"
july_start = Time.new(2026, 7, 1)
august_end = Time.new(2026, 8, 31)
summer_events = repo.filter_by_date_range(july_start, august_end)
summer_events.each do |event|
  puts "  - #{event.name} on #{event.start_time.strftime('%B %d, %Y')}"
end
puts "  (Found #{summer_events.size} events)"

# Available events
puts "\nEvents with available seats:"
available = repo.available_events
available.each do |event|
  puts "  - #{event.name}: #{event.available_seats}/#{event.total_seats} available"
end
puts

# ============================================================================
# SORTING
# ============================================================================

puts '-' * 80
puts '3. SORTING'
puts '-' * 80

puts "\nEvents sorted by start time:"
by_time = repo.sort_by_start_time
by_time.each do |event|
  puts "  - #{event.start_time.strftime('%Y-%m-%d')}: #{event.name}"
end

puts "\nEvents sorted by capacity (largest first):"
by_seats = repo.sort_by_seats
by_seats.each do |event|
  puts "  - #{event.name}: #{event.total_seats} seats"
end
puts

# ============================================================================
# CHAINING OPERATIONS
# ============================================================================

puts '-' * 80
puts '4. CHAINING OPERATIONS (The Ruby Way!)'
puts '-' * 80

# Complex query: Ruby events in SF, with 100+ seats, sorted by date
puts "\nComplex query: Ruby events in SF with 100+ seats:"
results = repo.all
              .select { |e| e.name.downcase.include?('ruby') }
              .select { |e| e.venue.name.include?('San Francisco') }
              .select { |e| e.total_seats >= 100 }
              .sort_by(&:start_time)

if results.any?
  results.each do |event|
    puts "  - #{event.name}"
    puts "    Venue: #{event.venue}"
    puts "    Seats: #{event.total_seats}"
    puts "    Date: #{event.start_time.strftime('%B %d, %Y')}"
    puts
  end
else
  puts '  (No matching events)'
end

# Using Enumerable methods directly
puts "Using Ruby's Enumerable methods:"

# Group by month
puts "\nEvents grouped by month:"
by_month = repo.all.group_by { |e| e.start_time.strftime('%B %Y') }
by_month.each do |month, month_events|
  puts "  #{month}:"
  month_events.each { |e| puts "    - #{e.name}" }
end

# Count events by venue city
puts "\nEvent count by city:"
city_counts = repo.all
                  .map { |e| e.venue.name.split.last } # Extract city (simplified)
                  .tally # Count occurrences (Ruby 2.7+ feature!)
city_counts.each { |city, count| puts "  #{city}: #{count} events" }

# Find most popular (largest) event
puts "\nMost popular event (by seats):"
largest = repo.all.max_by(&:total_seats)
puts "  #{largest.name} with #{largest.total_seats} seats"

# Calculate total capacity
puts "\nTotal capacity across all events:"
total = repo.all.sum(&:total_seats) # Ruby 2.4+ feature!
puts "  #{total} seats total"
puts

# ============================================================================
# LAZY EVALUATION EXAMPLE
# ============================================================================

puts '-' * 80
puts '5. LAZY EVALUATION (For Large Collections)'
puts '-' * 80

# Simulate a large collection
puts "\nSimulating repository with 1,000,000 events..."
puts '(Using lazy evaluation to find first 3 Ruby events)'

# Create a lazy enumerator
huge_range = (1..1_000_000).lazy.map do |i|
  # This would create events, but we'll just demonstrate the concept
  "Event #{i}"
end

# Find first 3 that match a condition
first_three = huge_range
              .select { |name| name.include?('1') }
              .first(3)

puts "First 3 events with '1' in name: #{first_three.inspect}"
puts "(Stopped after finding 3, didn't process all million!)"
puts

# ============================================================================
# SUMMARY
# ============================================================================

puts '=' * 80
puts 'DEMONSTRATION COMPLETE!'
puts '=' * 80
puts
puts 'Key Concepts Demonstrated:'
puts '  ✓ Repository Pattern - Clean data access abstraction'
puts '  ✓ Enumerable methods - select, find, map, sort_by, etc.'
puts '  ✓ Method chaining - Combine operations elegantly'
puts '  ✓ Blocks and closures - Flexible filtering'
puts '  ✓ Symbol-to-proc (&:method_name) - Concise syntax'
puts '  ✓ Lazy evaluation - Performance optimization'
puts
puts 'Next Steps:'
puts '  1. Run tests: docker-compose run --rm app bundle exec rspec'
puts '  2. Read: DAY_2_SUMMARY.md'
puts '  3. Try: Exercises in DAY_2_EXERCISES.md'
puts '=' * 80
