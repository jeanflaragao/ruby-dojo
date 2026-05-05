# frozen_string_literal: true

# Ruby Collections Tutorial - Day 2
# Run this file: docker compose run --rm app ruby lib/collections_tutorial.rb

puts '=' * 70
puts 'Ruby Collections - Interactive Tutorial'
puts '=' * 70
puts

# ============================================================================
# ARRAYS - Ordered collections
# ============================================================================

puts '1. ARRAYS - Ordered, indexed collections'
puts '-' * 70

# Creating arrays
numbers = [1, 2, 3, 4, 5]
names = %w[Alice Bob Charlie]
mixed = [1, 'two', :three, 4.0] # Ruby allows mixed types!

puts "Array of numbers: #{numbers.inspect}"
puts "Array of names: #{names.inspect}"
puts "Mixed types: #{mixed.inspect}"
puts

# Accessing elements
puts "First element: #{numbers[0]}"        # => 1
puts "Last element: #{numbers[-1]}"        # => 5 (negative index from end!)
puts "First 3: #{numbers[0..2].inspect}"   # => [1, 2, 3] (range syntax)
puts

# WHY negative indexing? Common pattern - get last element without knowing length
# Python has this too. Java/C++: array[array.length - 1]
# Ruby: array[-1]

# ============================================================================
# HASHES - Key-value pairs (like dictionaries/maps)
# ============================================================================

puts "\n2. HASHES - Key-value pairs"
puts '-' * 70

# Creating hashes
person = { 'name' => 'Alice', 'age' => 30, 'city' => 'SF' } # String keys
event = { name: 'RubyConf', seats: 500, sold_out: false } # Symbol keys (preferred!)

puts "Person hash: #{person.inspect}"
puts "Event hash: #{event.inspect}"
puts

# Accessing values
puts "Person name: #{person['name']}"
puts "Event seats: #{event[:seats]}"
puts

# WHY symbols as keys?
# - Symbols are immutable and unique in memory
# - { name: 'value' } is syntactic sugar for { :name => 'value' }
# - Convention: symbols for fixed keys, strings for user input

# ============================================================================
# SYMBOLS vs STRINGS - When to use which?
# ============================================================================

puts "\n3. SYMBOLS vs STRINGS - The Big Question"
puts '-' * 70

string1 = 'hello'
string2 = 'hello'
symbol1 = :hello
symbol2 = :hello

puts "String object IDs: #{string1.object_id} vs #{string2.object_id}"  # Different!
puts "Symbol object IDs: #{symbol1.object_id} vs #{symbol2.object_id}"  # Same!
puts

puts 'USE SYMBOLS FOR:'
puts "  - Hash keys (identifiers): { name: 'Alice' }"
puts '  - Method names: send(:upcase)'
puts '  - Constants/identifiers: status: :active'
puts
puts 'USE STRINGS FOR:'
puts "  - User input: params['username']"
puts "  - Text content: message = 'Hello, world!'"
puts '  - Data that needs manipulation'
puts

# ============================================================================
# ENUMERABLE MODULE - Ruby's Secret Weapon
# ============================================================================

puts "\n4. ENUMERABLE MODULE - Where Ruby Shines!"
puts '-' * 70

events = [
  { name: 'RubyConf', seats: 500, price: 299 },
  { name: 'RailsConf', seats: 800, price: 399 },
  { name: 'React Summit', seats: 300, price: 199 },
  { name: 'JS Conf', seats: 400, price: 249 }
]

puts 'Original events:'
events.each { |e| puts "  - #{e[:name]}: #{e[:seats]} seats, $#{e[:price]}" }
puts

# MAP - Transform each element
# WHY it's called 'map'? Maps one collection to another
names_only = events.map { |e| e[:name] }
puts "MAP - Extract just names: #{names_only.inspect}"

prices_doubled = events.map { |e| e[:price] * 2 }
puts "MAP - Double all prices: #{prices_doubled.inspect}"
puts

# SELECT - Filter elements (keep those where block returns true)
# WHY 'select'? Selects elements that match condition
big_events = events.select { |e| e[:seats] >= 500 }
puts 'SELECT - Events with 500+ seats:'
big_events.each { |e| puts "  - #{e[:name]}" }
puts

# REJECT - Opposite of select (keep those where block returns false)
small_events = events.reject { |e| e[:seats] >= 500 }
puts 'REJECT - Events with < 500 seats:'
small_events.each { |e| puts "  - #{e[:name]}" }
puts

# FIND - Get first element that matches
# WHY 'find' vs 'select'? Returns single element, not array
expensive = events.find { |e| e[:price] > 300 }
puts "FIND - First event over $300: #{expensive[:name]}"
puts

# REDUCE - Combine all elements into single value
# WHY 'reduce'? Reduces collection to single value
# Also called 'fold' in other languages
total_seats = events.reduce(0) { |sum, e| sum + e[:seats] }
puts "REDUCE - Total seats across all events: #{total_seats}"
puts

# ANY? / ALL? / NONE? - Boolean queries
puts "ANY? - Any event over $350? #{events.any? { |e| e[:price] > 350 }}"
puts "ALL? - All events under $500? #{events.all? { |e| e[:price] < 500 }}"
puts "NONE? - No events over $1000? #{events.none? { |e| e[:price] > 1000 }}"
puts

# SORT_BY - Sort by specific attribute
by_price = events.sort_by { |e| e[:price] }
puts 'SORT_BY - Events by price (ascending):'
by_price.each { |e| puts "  - #{e[:name]}: $#{e[:price]}" }
puts

# GROUP_BY - Group into hash by attribute
by_size = events.group_by { |e| e[:seats] >= 500 ? 'large' : 'small' }
puts 'GROUP_BY - Events grouped by size:'
puts "  Large: #{by_size['large'].map { |e| e[:name] }.join(', ')}"
puts "  Small: #{by_size['small'].map { |e| e[:name] }.join(', ')}"
puts

# ============================================================================
# CHAINING - Combine multiple operations
# ============================================================================

puts "\n5. CHAINING - Combine operations elegantly"
puts '-' * 70

# Find names of affordable events (< $300), sorted by price
affordable_names = events
                   .select { |e| e[:price] < 300 } # Filter
                   .sort_by { |e| e[:price] } # Sort
                   .map { |e| e[:name] } # Extract names

puts 'Chained operations - Affordable events, sorted:'
affordable_names.each { |name| puts "  - #{name}" }
puts

# WHY chaining works? Each method returns a new collection
# Think: Unix pipes: cat file | grep pattern | sort

# ============================================================================
# BLOCKS, PROCS, LAMBDAS - Ruby's Closures
# ============================================================================

puts "\n6. BLOCKS, PROCS, LAMBDAS - The Three Amigos"
puts '-' * 70

# BLOCKS - Anonymous code chunks
puts 'BLOCK - Passed to method:'
[1, 2, 3].each { |n| puts "  Number: #{n}" }
puts

# Can also use do...end syntax (for multi-line)
[1, 2, 3].each do |n|
  doubled = n * 2
  puts "  #{n} doubled is #{doubled}"
end
puts

# PROCS - Reusable blocks (objects)
doubler = proc { |n| n * 2 }
puts 'PROC - Reusable block:'
puts "  doubler.call(5) = #{doubler.call(5)}"
puts "  [1,2,3].map(&doubler) = #{[1, 2, 3].map(&doubler).inspect}"
puts

# LAMBDAS - Stricter procs (check arguments, different return behavior)
tripler = ->(n) { n * 3 } # Stabby lambda syntax
puts 'LAMBDA - Stricter proc:'
puts "  tripler.call(5) = #{tripler.call(5)}"
puts "  [1,2,3].map(&tripler) = #{[1, 2, 3].map(&tripler).inspect}"
puts

# WHY three types?
# - Blocks: Syntax, not objects. Used with iterators.
# - Procs: Objects, flexible, forgiving
# - Lambdas: Objects, strict, act like methods

# ============================================================================
# LAZY EVALUATION - Performance optimization
# ============================================================================

puts "\n7. LAZY EVALUATION - For large collections"
puts '-' * 70

# Imagine we have millions of events...
huge_range = (1..1_000_000)

# EAGER evaluation - processes everything immediately
puts 'EAGER - All operations happen immediately:'
# result = huge_range.select { |n| n.even? }.map { |n| n * 2 }.first(5)
# This creates intermediate arrays! Memory intensive!

# LAZY evaluation - only computes what's needed
puts "LAZY - Only computes what's needed:"
result = huge_range.lazy.select(&:even?).map { |n| n * 2 }.first(5)
puts "  First 5 even numbers doubled: #{result.inspect}"
puts

# WHY lazy? Performance! Stops after finding first 5 matches
# Doesn't create intermediate arrays
# Essential for infinite sequences or huge datasets

# ============================================================================
# PRACTICAL EXAMPLE - Combining everything
# ============================================================================

puts "\n8. PRACTICAL EXAMPLE - Event search"
puts '-' * 70

all_events = [
  { name: 'Ruby Meetup SF', venue: 'San Francisco', seats: 50, available: 10, price: 0 },
  { name: 'RubyConf 2026', venue: 'San Francisco', seats: 500, available: 100, price: 299 },
  { name: 'Rails Workshop', venue: 'New York', seats: 30, available: 0, price: 199 },
  { name: 'React Summit', venue: 'San Francisco', seats: 300, available: 200, price: 199 }
]

# Complex query: Find available events in SF, under $200, sorted by seats
results = all_events
          .select { |e| e[:venue] == 'San Francisco' } # Filter by location
          .select { |e| e[:available].positive? } # Filter by availability
          .select { |e| e[:price] < 200 } # Filter by price
          .sort_by { |e| -e[:seats] } # Sort by seats (descending)

puts 'Available SF events under $200, by size:'
results.each do |e|
  puts "  - #{e[:name]}: #{e[:available]}/#{e[:seats]} available, $#{e[:price]}"
end
puts

# This is EXACTLY what we'll build in EventRepository!

puts '=' * 70
puts 'Tutorial Complete!'
puts '=' * 70
puts
puts 'Key Takeaways:'
puts '1. Arrays and Hashes are your bread and butter'
puts '2. Enumerable module makes collections powerful'
puts '3. map, select, reduce are your best friends'
puts '4. Chaining makes complex queries readable'
puts '5. Lazy evaluation for performance'
puts
puts "Next: Let's build EventRepository with these concepts!"
