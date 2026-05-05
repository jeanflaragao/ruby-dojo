# frozen_string_literal: true

# EventRepository - In-memory storage and querying for Events
#
# DESIGN PATTERN: Repository Pattern
# WHY? Abstracts data access, making it easy to swap storage implementations
#
# RUBY CONCEPTS DEMONSTRATED:
# - Enumerable module and its methods (map, select, find, etc.)
# - Blocks and closures
# - Method chaining
# - Defensive copying (preventing external mutation)
# - Symbol-to-proc (&:method_name)
#
# FUTURE: This in-memory implementation will be replaced with
# ActiveRecord (PostgreSQL) on Day 8, but the interface stays the same!
require_relative '../searchable'

class EventRepository
  include Searchable

  # WHY attr_reader? Expose count, but not direct array access
  # Users must go through our methods (encapsulation)
  attr_reader :count

  # Initialize with optional events array
  # WHY default to []? Ruby idiom for optional array parameter
  def initialize(events = [])
    # Instance variable to store events
    # WHY @events? Private storage, accessed via methods
    @events = events.dup # Defensive copy - don't reference external array
    @count = @events.size
  end

  # Add an event to the repository
  # WHY return the event? Allows chaining: repo.add(event).name
  def add(event)
    @events << event
    @count += 1
    event # Return the added event
  end

  # Get all events
  # WHY dup? Return a copy so external code can't mutate our internal array
  # This is DEFENSIVE COPYING - important design principle
  def all
    @events.dup
  end

  # Find event by exact name match
  # WHY find vs select? find returns first match (single event)
  # select returns all matches (array)
  #
  # ENUMERABLE METHOD: find
  # Returns first element where block returns true, or nil
  def find_by_name(name)
    @events.find { |event| event.name == name }
  end

  # Search events by partial name match (case-insensitive)
  # WHY select? Returns all matching events
  #
  # ENUMERABLE METHOD: select (alias: filter)
  # Returns array of all elements where block returns true
  #
  # RUBY CONCEPT: String methods
  # - downcase: converts to lowercase
  # - include?: checks if string contains substring
  def search_by_name(query)
    return @events.dup if query.empty?

    query_lower = query.downcase
    @events.select { |event| event.name.downcase.include?(query_lower) }
  end

  # Filter events by venue (case-insensitive partial match)
  def filter_by_venue(venue_query)
    venue_lower = venue_query.downcase
    @events.select { |event| event.venue.name.downcase.include?(venue_lower) }
  end

  # Filter events by date range
  # WHY between? Check if event start_time falls within range
  #
  # RUBY CONCEPT: Range with cover? or between?
  # (start_date..end_date).cover?(time) checks if time is in range
  def filter_by_date_range(start_date, end_date)
    @events.select do |event|
      event.start_time.between?(start_date, end_date)
    end
  end

  # Get events with available seats
  # WHY available_seats > 0? Events with seats left to book
  def available_events
    @events.select { |event| event.available_seats.positive? }
  end

  # Sort events by start time (ascending)
  # WHY sort_by? Cleaner than sort { |a, b| a.start_time <=> b.start_time }
  #
  # ENUMERABLE METHOD: sort_by
  # Sorts by the value returned from the block
  #
  # SYMBOL-TO-PROC: &:start_time
  # Syntactic sugar for: { |event| event.start_time }
  # The & converts :start_time symbol to a proc
  def sort_by_start_time
    @events.sort_by(&:start_time)
  end

  # Sort events by total seats (descending - largest first)
  # WHY negative? Reverses sort order (descending)
  # Alternative: sort_by(&:total_seats).reverse
  def sort_by_seats
    @events.sort_by { |event| -event.total_seats }
  end

  # ADVANCED: Chain-friendly filtering
  # WHY return self? Allows chaining: repo.where(...).where(...).results
  # This is the QUERY OBJECT PATTERN (we'll explore more on Day 9)
  #
  # Example usage:
  #   repo.where { |e| e.venue == 'SF' }
  #       .where { |e| e.available_seats > 0 }
  #       .results
  #
  # NOTE: This is advanced - not tested yet, but shows the power of blocks

  def where(&)
    QueryBuilder.new(@events.select(&))
  end

  def find_by_venue(venue_name)
    @events.find { |event| event.venue.name.downcase == venue_name.downcase }
  end

  def filter_by_seat_range(min_seats, max_seats)
    @events.select { |event| event.available_seats.between?(min_seats, max_seats) }
  end

  def upcoming_events
    now = Time.now
    @events.select { |event| event.start_time > now }
  end

  def lazy_search(query)
    return @events.dup if query.empty?

    query_lower = query.downcase
    @events.lazy.select { |event| event.name.downcase.include?(query_lower) }
  end

  def all_active
    @events.reject(&:deleted?)
  end

  def all_deleted
    @events.select(&:deleted?)
  end

  def events_in_price_range(min_price, max_price)
    @events.select do |event|
      event.base_price.between?(min_price, max_price)
    end
  end

  def events_in_date_range(date_range)
    @events.select do |event|
      date_range.includes?(event.start_time.to_date)
    end
  end

  def available_events_with_min_seats(min_seats)
    @events.select do |event|
      !event.sold_out? && event.available_seats >= min_seats
    end
  end
end
