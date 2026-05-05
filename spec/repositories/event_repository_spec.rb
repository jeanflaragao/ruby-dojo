# frozen_string_literal: true

require 'spec_helper'

# EventRepository - In-memory storage and querying for Events
# WHY? Separate data storage from business logic (Repository Pattern)
# BENEFITS:
# - Easy to test (no database needed)
# - Easy to swap storage later (PostgreSQL, Redis, etc.)
# - Clean separation of concerns

RSpec.describe EventRepository do
  # Sample events for testing
  # WHY let? Creates fresh instances for each test
  let(:event1) do
    Event.new(
      name: 'RubyConf 2026',
      description: 'Annual Ruby conference',
      venue: Venue.new(name: 'San Francisco Convention Center', address: '123 Main St, San Francisco, CA',
                       capacity: 500),
      start_time: Time.new(2026, 6, 15, 9, 0, 0),
      end_time: Time.new(2026, 6, 17, 18, 0, 0),
      total_seats: 500
    )
  end

  let(:event2) do
    Event.new(
      name: 'Rails Workshop',
      description: 'Hands-on Rails training',
      venue: Venue.new(name: 'New York Training Center', address: '456 Broadway, New York, NY', capacity: 30),
      start_time: Time.new(2026, 7, 10, 9, 0, 0),
      end_time: Time.new(2026, 7, 10, 17, 0, 0),
      total_seats: 30
    )
  end

  let(:event3) do
    Event.new(
      name: 'Ruby Meetup',
      description: 'Monthly Ruby meetup',
      venue: Venue.new(name: 'San Francisco Coffee Shop', address: '789 Market St, San Francisco, CA', capacity: 50),
      start_time: Time.new(2026, 8, 5, 18, 0, 0),
      end_time: Time.new(2026, 8, 5, 20, 0, 0),
      total_seats: 50
    )
  end

  describe '#initialize' do
    it 'creates an empty repository' do
      repo = described_class.new
      expect(repo.all).to be_empty
    end

    it 'accepts initial events' do
      repo = described_class.new([event1, event2])
      expect(repo.all.size).to eq(2)
    end
  end

  describe '#add' do
    subject(:repo) { described_class.new }

    it 'adds an event to the repository' do
      repo.add(event1)
      expect(repo.all).to include(event1)
    end

    it 'returns the added event' do
      result = repo.add(event1)
      expect(result).to eq(event1)
    end

    it 'increments the count' do
      expect { repo.add(event1) }.to change(repo, :count).from(0).to(1)
    end

    context 'when adding duplicate events' do
      it 'allows duplicate events' do
        # WHY allow duplicates? We'll add ID-based uniqueness later
        repo.add(event1)
        repo.add(event1)
        expect(repo.count).to eq(2)
      end
    end
  end

  describe '#all' do
    it 'returns all events' do
      repo = described_class.new([event1, event2, event3])
      expect(repo.all).to contain_exactly(event1, event2, event3)
    end

    it 'returns a copy, not the internal array' do
      # WHY? Prevent external code from mutating our internal state
      repo = described_class.new([event1])
      all_events = repo.all
      all_events << event2

      expect(repo.count).to eq(1) # Should not be affected
    end
  end

  describe '#count' do
    it 'returns 0 for empty repository' do
      repo = described_class.new
      expect(repo.count).to eq(0)
    end

    it 'returns the number of events' do
      repo = described_class.new([event1, event2, event3])
      expect(repo.count).to eq(3)
    end
  end

  describe '#find_by_name' do
    subject(:repo) { described_class.new([event1, event2, event3]) }

    context 'when event exists' do
      it 'finds event by exact name' do
        result = repo.find_by_name('RubyConf 2026')
        expect(result).to eq(event1)
      end

      it 'is case-sensitive by default' do
        result = repo.find_by_name('rubyconf 2026')
        expect(result).to be_nil
      end
    end

    context 'when event does not exist' do
      it 'returns nil' do
        result = repo.find_by_name('NonExistent Event')
        expect(result).to be_nil
      end
    end
  end

  describe '#search_by_name' do
    subject(:repo) { described_class.new([event1, event2, event3]) }

    it 'finds events with partial name match' do
      results = repo.search_by_name('Ruby')
      expect(results).to contain_exactly(event1, event3)
    end

    it 'is case-insensitive' do
      results = repo.search_by_name('ruby')
      expect(results).to contain_exactly(event1, event3)
    end

    it 'returns empty array when no matches' do
      results = repo.search_by_name('Python')
      expect(results).to be_empty
    end

    it 'returns all events when query is empty' do
      results = repo.search_by_name('')
      expect(results).to contain_exactly(event1, event2, event3)
    end
  end

  describe '#filter_by_venue' do
    subject(:repo) { described_class.new([event1, event2, event3]) }

    it 'filters events by exact venue match' do
      results = repo.filter_by_venue('San Francisco Convention Center')
      expect(results).to contain_exactly(event1)
    end

    it 'supports partial venue matching' do
      results = repo.filter_by_venue('San Francisco')
      expect(results).to contain_exactly(event1, event3)
    end

    it 'is case-insensitive' do
      results = repo.filter_by_venue('san francisco')
      expect(results).to contain_exactly(event1, event3)
    end
  end

  describe '#filter_by_date_range' do
    subject(:repo) { described_class.new([event1, event2, event3]) }

    it 'finds events starting within date range' do
      # Events starting in July 2026
      start_date = Time.new(2026, 7, 1)
      end_date = Time.new(2026, 7, 31)

      results = repo.filter_by_date_range(start_date, end_date)
      expect(results).to contain_exactly(event2)
    end

    it 'includes events on boundary dates' do
      # Exact start time of event2
      start_date = Time.new(2026, 7, 10, 9, 0, 0)
      end_date = Time.new(2026, 7, 10, 9, 0, 0)

      results = repo.filter_by_date_range(start_date, end_date)
      expect(results).to contain_exactly(event2)
    end

    it 'returns empty array when no events in range' do
      start_date = Time.new(2027, 1, 1)
      end_date = Time.new(2027, 12, 31)

      results = repo.filter_by_date_range(start_date, end_date)
      expect(results).to be_empty
    end
  end

  describe '#available_events' do
    subject(:repo) { described_class.new([event1, event2, event3]) }

    let(:sold_out_event) do
      event = Event.new(
        name: 'Sold Out Conference',
        description: 'No seats left',
        venue: 'Venue',
        start_time: Time.now,
        end_time: Time.now + 3600,
        total_seats: 100
      )
      # Simulate sold out by reserving all seats
      # NOTE: This requires reserve_seats method from Exercise 2!
      # For now, we'll test the concept with available_seats > 0
      event
    end

    it 'returns events with available seats' do
      results = repo.available_events
      # All our test events have available_seats = total_seats
      expect(results).to contain_exactly(event1, event2, event3)
    end
  end

  describe '#sort_by_start_time' do
    subject(:repo) { described_class.new([event2, event3, event1]) }

    it 'sorts events by start time ascending' do
      results = repo.sort_by_start_time
      expect(results).to eq([event1, event2, event3])
    end

    it 'returns a new array' do
      sorted = repo.sort_by_start_time
      sorted << Event.new(
        name: 'New',
        description: 'D',
        venue: Venue.new(name: 'New Venue', address: 'Address', capacity: 100),
        start_time: Time.now,
        end_time: Time.now + 1,
        total_seats: 1
      )
      expect(repo.count).to eq(3) # Original unchanged
    end
  end

  describe '#sort_by_seats' do
    subject(:repo) { described_class.new([event1, event2, event3]) }

    it 'sorts events by total seats descending' do
      # event1: 500, event3: 50, event2: 30
      results = repo.sort_by_seats
      expect(results).to eq([event1, event3, event2])
    end
  end

  describe '#events_in_price_range' do
    let(:venue) do
      Venue.new(
        name: 'Convention Center',
        address: '123 Main St',
        capacity: 1000
      )
    end

    it 'filters events by price range' do
      cheap = Event.new(
        name: 'Ruby Conference',
        description: 'Annual Ruby event',
        venue: venue,
        start_time: Time.new(2024, 6, 1, 10, 0, 0),
        end_time: Time.new(2024, 6, 1, 18, 0, 0),
        total_seats: 10,
        base_price: Money.new(50, 'USD')
      )

      mid = Event.new(
        name: 'Ruby Meetup',
        description: 'Monthly Ruby meetup',
        venue: venue,
        start_time: Time.new(2024, 6, 15, 10, 0, 0),
        end_time: Time.new(2024, 6, 15, 18, 0, 0),
        total_seats: 200,
        base_price: Money.new(100, 'USD')
      )

      expensive = Event.new(
        name: 'Ruby Gala',
        description: 'Exclusive Ruby event',
        venue: venue,
        start_time: Time.new(2024, 6, 20, 10, 0, 0),
        end_time: Time.new(2024, 6, 20, 18, 0, 0),
        total_seats: 50,
        base_price: Money.new(200, 'USD')
      )

      repo = described_class.new([cheap, mid, expensive])

      results = repo.events_in_price_range(
        Money.new(75, 'USD'),
        Money.new(150, 'USD')
      )

      expect(results).to include(mid)
      expect(results).not_to include(cheap, expensive)
    end
  end

  describe '#events_in_date_range' do
    it 'filters events by date range' do
      june = Event.new(
        name: 'June Event',
        description: 'Event in June',
        venue: Venue.new(
          name: 'Convention Center',
          address: '123 Main St',
          capacity: 100
        ),
        start_time: Time.new(2026, 6, 1),
        end_time: Time.new(2026, 6, 30),
        total_seats: 100,
        base_price: Money.new(100, 'USD')
      )
      july = Event.new(
        name: 'July Event',
        description: 'Event in July',
        venue: Venue.new(
          name: 'Convention Center',
          address: '123 Main St',
          capacity: 100
        ),
        start_time: Time.new(2026, 7, 1),
        end_time: Time.new(2026, 7, 31),
        total_seats: 100,
        base_price: Money.new(100, 'USD')
      )
      august = Event.new(
        name: 'August Event',
        description: 'Event in August',
        venue: Venue.new(
          name: 'Convention Center',
          address: '123 Main St',
          capacity: 100
        ),
        start_time: Time.new(2026, 8, 1),
        end_time: Time.new(2026, 8, 31),
        total_seats: 100,
        base_price: Money.new(100, 'USD')
      )

      repo = described_class.new([june, july, august])

      date_range = DateRange.new(
        Date.new(2026, 6, 1),
        Date.new(2026, 7, 15)
      )

      results = repo.events_in_date_range(date_range)

      expect(results).to include(june, july)
      expect(results).not_to include(august)
    end
  end

  describe '#available_events_with_min_seats' do
    it 'filters events with enough available seats' do
      full = Event.new(
        name: 'Full Event',
        description: 'Sold out event',
        venue: Venue.new(
          name: 'Convention Center',
          address: '123 Main St',
          capacity: 10
        ),
        start_time: Time.new(2026, 6, 1),
        end_time: Time.new(2026, 6, 2),
        total_seats: 10,
        base_price: Money.new(100, 'USD')
      )
      full.reserve_seats(10) # Sold out

      partial = Event.new(
        name: 'Partial Event',
        description: 'Almost sold out event',
        venue: Venue.new(
          name: 'Convention Center',
          address: '123 Main St',
          capacity: 100
        ),
        start_time: Time.new(2026, 6, 3),
        end_time: Time.new(2026, 6, 4),
        total_seats: 100,
        base_price: Money.new(100, 'USD')
      )
      partial.reserve_seats(95) # 5 left

      plenty = Event.new(
        name: 'Plenty Event',
        description: 'Event with plenty of seats',
        venue: Venue.new(
          name: 'Convention Center',
          address: '123 Main St',
          capacity: 100
        ),
        start_time: Time.new(2026, 6, 5),
        end_time: Time.new(2026, 6, 6),
        total_seats: 100,
        base_price: Money.new(100, 'USD')
      )

      repo = described_class.new([full, partial, plenty])

      results = repo.available_events_with_min_seats(10)

      expect(results).to include(plenty)
      expect(results).not_to include(full, partial)
    end
  end

  # SHARED EXAMPLES - DRY testing pattern
  # WHY? Reusable test scenarios
  RSpec.shared_examples 'returns a collection' do
    it 'returns an Array' do
      expect(result).to be_a(Array)
    end

    it 'returns Event objects' do
      expect(result).to all(be_a(Event))
    end
  end

  describe '#search_by_name' do
    subject(:repo) { described_class.new([event1]) }

    let(:result) { repo.search_by_name('Ruby') }

    it_behaves_like 'returns a collection'
  end

  describe '#filter_by_venue' do
    subject(:repo) { described_class.new([event1]) }

    let(:result) { repo.filter_by_venue('San Francisco') }

    it_behaves_like 'returns a collection'
  end

  # CHAINING OPERATIONS - Real-world usage
  describe 'chaining operations' do
    subject(:repo) { described_class.new([event1, event2, event3]) }

    it 'supports method chaining for complex queries' do
      # Find Ruby events in San Francisco, sorted by size
      results = repo
                .search_by_name('Ruby')
                .select { |e| e.venue.name.include?('San Francisco') }
                .sort_by(&:total_seats)
                .reverse

      expect(results.first).to eq(event1) # Largest Ruby event in SF
    end
  end

  describe '#find_by_venue' do
    subject(:repo) { described_class.new([event1, event2, event3]) }

    context 'when venue exists' do
      it 'returns the first event at that venue' do
        result = repo.find_by_venue('San Francisco Convention Center')
        expect(result).to eq(event1)
      end
    end

    context 'when venue does not exist' do
      it 'returns nil' do
        result = repo.find_by_venue('Nonexistent Venue')
        expect(result).to be_nil
      end
    end

    context 'when multiple events at same venue' do
      let(:event4) do
        Event.new(
          name: 'Another Ruby Event',
          description: 'More Ruby',
          venue: Venue.new(
            name: 'San Francisco Convention Center',
            address: '123 Main St, San Francisco, CA',
            capacity: 200
          ),
          start_time: Time.new(2026, 9, 1),
          end_time: Time.new(2026, 9, 2),
          total_seats: 200
        )
      end

      it 'returns the first one' do
        repo.add(event4)
        result = repo.find_by_venue('San Francisco Convention Center')
        expect(result).to eq(event1) # First one added
      end
    end
  end

  describe '#filter_by_seat_range' do
    subject(:repo) { described_class.new(events) }

    let(:events) do
      [
        Event.new(name: 'Small', description: 'D', venue: Venue.new(name: 'Venue 1', address: 'Address', capacity: 20),
                  start_time: Time.now, end_time: Time.now + 1, total_seats: 20),
        Event.new(name: 'Medium', description: 'D', venue: Venue.new(name: 'Venue 2', address: 'Address', capacity: 100),
                  start_time: Time.now, end_time: Time.now + 1, total_seats: 100),
        Event.new(name: 'Large', description: 'D', venue: Venue.new(name: 'Venue 3', address: 'Address', capacity: 500),
                  start_time: Time.now, end_time: Time.now + 1, total_seats: 500)
      ]
    end

    it 'filters events within seat range' do
      results = repo.filter_by_seat_range(50, 200)
      expect(results).to contain_exactly(events[1]) # Medium event
    end

    it 'includes boundary values' do
      results = repo.filter_by_seat_range(100, 500)
      expect(results).to contain_exactly(events[1], events[2])
    end

    it 'returns empty array when no matches' do
      results = repo.filter_by_seat_range(1000, 2000)
      expect(results).to be_empty
    end

    it 'works with min = max' do
      results = repo.filter_by_seat_range(100, 100)
      expect(results).to contain_exactly(events[1])
    end
  end

  describe '#upcoming_events' do
    subject(:repo) { described_class.new([past_event, future_event]) }

    let(:past_event) do
      Event.new(
        name: 'Past Event',
        description: 'Already happened',
        venue: Venue.new(name: 'Venue', address: 'Address', capacity: 100),
        start_time: Time.now - 86_400,  # Yesterday
        end_time: Time.now - 3600,
        total_seats: 100
      )
    end

    let(:future_event) do
      Event.new(
        name: 'Future Event',
        description: 'Coming soon',
        venue: Venue.new(name: 'Venue', address: 'Address', capacity: 100),
        start_time: Time.now + 86_400,  # Tomorrow
        end_time: Time.now + 90_000,
        total_seats: 100
      )
    end

    it 'returns only events starting in the future' do
      results = repo.upcoming_events
      expect(results).to contain_exactly(future_event)
    end

    it 'excludes events that already started' do
      results = repo.upcoming_events
      expect(results).not_to include(past_event)
    end

    it 'sorts by start time (soonest first)' do
      event_in_week = Event.new(
        name: 'Next Week',
        description: 'D',
        venue: Venue.new(name: 'Venue', address: 'Address', capacity: 50),
        start_time: Time.now + 604_800, # 1 week
        end_time: Time.now + 608_400,
        total_seats: 50
      )

      repo.add(event_in_week)
      results = repo.upcoming_events
      expect(results.first).to eq(future_event) # Tomorrow comes first
    end
  end

  describe 'query chaining' do
    subject(:repo) { described_class.new([past_event, future_event]) }

    let(:past_event) do
      Event.new(
        name: 'Past Event',
        description: 'Already happened',
        venue: Venue.new(name: 'SFD', address: 'Address', capacity: 101),
        start_time: Time.now - 86_400,  # Yesterday
        end_time: Time.now - 3600,
        total_seats: 101
      )
    end

    let(:future_event) do
      Event.new(
        name: 'Future Event',
        description: 'Coming soon',
        venue: Venue.new(name: 'SFD', address: 'Address', capacity: 100),
        start_time: Time.now + 86_400,  # Tomorrow
        end_time: Time.now + 90_000,
        total_seats: 100
      )
    end

    it 'supports multiple where clauses' do
      results = repo
                .where { |e| e.venue.name.include?('SF') }
                .where { |e| e.total_seats > 100 }
                .results

      expect(results).to all(satisfy { |e| e.venue.name.include?('SF') })
      expect(results).to all(satisfy { |e| e.total_seats > 100 })
    end

    it 'supports ordering' do
      results = repo
                .where { |e| e.available_seats > 0 }
                .order_by(:start_time)
                .results

      expect(results).to eq(results.sort_by(&:start_time))
    end

    it 'supports limit' do
      results = repo
                .where { |e| e.available_seats > 0 }
                .limit(2)
                .results

      expect(results.size).to eq(2)
    end
  end

  describe '#lazy_search' do
    subject(:repo) { described_class.new([event1, event2, event3]) }

    it 'returns a lazy enumerator' do
      result = repo.lazy_search('Ruby')
      expect(result).to be_a(Enumerator::Lazy)
    end

    it 'can be materialized with force' do
      result = repo.lazy_search('Ruby').force
      expect(result).to be_a(Array)
    end

    it 'supports chaining' do
      result = repo
               .lazy_search('Ruby')
               .select { |e| e.total_seats > 100 }
               .first(3)

      expect(result.size).to be <= 3
    end
  end
end
