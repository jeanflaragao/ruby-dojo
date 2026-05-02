# lib/event_collection.rb
class EventCollection
  include Enumerable  # This gives us map, select, find, etc. for FREE!

  def initialize(events = [])
    @events = events
  end

  # The ONLY method you need to implement for Enumerable!
  # All other methods (map, select, find, etc.) are defined in terms of each
  def each(&block)
    # Your implementation here
    # Hint: @events.each(&block)
    @events.each(&block)
  end
end