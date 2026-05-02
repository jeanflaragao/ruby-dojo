# frozen_string_literal: true

# WHY require spec_helper? Loads RSpec config and our application code
require 'spec_helper'

# describe: Groups related tests for a class/module
# WHY Event? We're testing the Event class behavior
RSpec.describe Event do
  # Context: Groups tests under specific conditions
  # WHY "when creating a new event"? Specific scenario we're testing
  describe '#initialize' do
    context 'when all required attributes are provided' do
      # let: Lazy-loaded test data (memoized)
      # WHY let vs instance variables?
      # - let is lazy (only created when used)
      # - let is memoized (same instance within one test)
      # - let provides better isolation between tests
      # subject: The thing we're testing
      # WHY subject? DRY - reuse the same object creation
      subject(:event) do
        described_class.new(
          name: name,
          description: description,
          venue: venue,
          start_time: start_time,
          end_time: end_time,
          total_seats: total_seats
        )
      end

      let(:venue) do
        Venue.new(
          name: 'Convention Center',
          address: '123 Main St',
          capacity: 1000
        )
      end
      let(:name) { 'Ruby Conference 2026' }
      let(:description) { 'Annual Ruby developer conference' }
      let(:start_time) { Time.new(2026, 6, 15, 9, 0, 0) }
      let(:end_time) { Time.new(2026, 6, 17, 18, 0, 0) }
      let(:total_seats) { 500 }

      context 'when venue capacity is less than total_seats' do
        it 'raises an error' do
          expect do
            described_class.new(
              name: 'Big Event',
              description: 'Too big for venue',
              venue: venue,
              start_time: Time.now,
              end_time: Time.now + 3600,
              total_seats: 2000 # More than venue.capacity!
            )
          end.to raise_error(ArgumentError, /exceeds venue capacity/)
        end
      end

      # it: Individual test case
      # WHY descriptive strings? Tests are documentation
      it 'creates an event with the given name' do
        # expect().to eq() - RSpec matcher for equality
        # WHY eq vs ==? eq uses == but provides better failure messages
        expect(event.name).to eq(name)
      end

      it 'creates an event with the given description' do
        expect(event.description).to eq(description)
      end

      it 'creates an event with the given venue' do
        expect(event.venue).to eq(venue)
      end

      it 'creates an event with the given start time' do
        expect(event.start_time).to eq(start_time)
      end

      it 'creates an event with the given end time' do
        expect(event.end_time).to eq(end_time)
      end

      it 'creates an event with the given total seats' do
        expect(event.total_seats).to eq(total_seats)
      end

      it 'initializes available seats to total seats' do
        # WHY test this? Business rule: new events have all seats available
        expect(event.available_seats).to eq(total_seats)
      end
    end

    context 'when required attributes are missing' do
      it 'raises ArgumentError when name is missing' do
        # expect { }.to raise_error - tests for exceptions
        # WHY block syntax? Exception happens during execution
        expect do
          described_class.new(
            name: nil,
            description: 'Description',
            venue: Venue.new(
              name: 'Convention Center',
              address: '123 Main St',
              capacity: 1000
            ),
            start_time: Time.now,
            end_time: Time.now + 3600,
            total_seats: 100
          )
        end.to raise_error(ArgumentError, /name is required/)
      end

      it 'raises ArgumentError when total_seats is missing' do
        expect do
          described_class.new(
            name: 'Event',
            description: 'Description',
            venue: Venue.new(
              name: 'Convention Center',
              address: '123 Main St',
              capacity: 1000
            ),
            start_time: Time.now,
            end_time: Time.now + 3600,
            total_seats: nil
          )
        end.to raise_error(ArgumentError, /total_seats is required/)
      end
    end

    context 'when validating business rules' do
      let(:start_time) { Time.new(2026, 6, 15, 9, 0, 0) }

      it 'raises error when end_time is before start_time' do
        # WHY test this? Data integrity - events can't end before they start
        expect do
          described_class.new(
            name: 'Bad Event',
            description: 'Description',
            venue: Venue.new(
              name: 'Convention Center',
              address: '123 Main St',
              capacity: 1000
            ),
            start_time: start_time,
            end_time: start_time - 3600, # 1 hour before start
            total_seats: 100
          )
        end.to raise_error(ArgumentError, /end_time must be after start_time/)
      end

      it 'raises error when total_seats is not positive' do
        expect do
          described_class.new(
            name: 'Event',
            description: 'Description',
            venue: Venue.new(
              name: 'Convention Center',
              address: '123 Main St',
              capacity: 1000
            ),
            start_time: start_time,
            end_time: start_time + 3600,
            total_seats: 0
          )
        end.to raise_error(ArgumentError, /total_seats must be positive/)
      end

      it 'raises error when total_seats is negative' do
        expect do
          described_class.new(
            name: 'Event',
            description: 'Description',
            venue: Venue.new(
              name: 'Convention Center',
              address: '123 Main St',
              capacity: 1000
            ),
            start_time: start_time,
            end_time: start_time + 3600,
            total_seats: -10
          )
        end.to raise_error(ArgumentError, /total_seats must be positive/)
      end
    end

    context 'when validating name length' do
      let(:base_params) do
        {
          description: 'Description',
          venue: Venue.new(
            name: 'Convention Center',
            address: '123 Main St',
            capacity: 1000
          ),
          start_time: Time.now,
          end_time: Time.now + 3600,
          total_seats: 100
        }
      end

      context 'when name is too short' do
        it 'raises an error for 2 characters' do
          expect do
            described_class.new(
              **base_params,
              name: 'ab'
            )
          end.to raise_error(ArgumentError, /name must be at least 3 characters long/)
        end

        it 'raises an error for 1 character' do
          expect do
            described_class.new(
              **base_params,
              name: 'a'
            )
          end.to raise_error(ArgumentError, /name must be at least 3 characters long/)
        end

        it 'raises an error for empty string' do
          expect do
            described_class.new(
              **base_params,
              name: ''
            )
          end.to raise_error(ArgumentError, /name is required/)
        end
      end

      context 'when name is too long' do
        it 'raises an error for 101 characters' do
          long_name = 'a' * 101
          expect do
            described_class.new(
              **base_params,
              name: long_name
            )
          end.to raise_error(ArgumentError, /name must be at most 100 characters long/)
        end
      end

      context 'when name length is valid' do
        it 'accepts 3 characters (minimum)' do
          event = described_class.new(
            **base_params,
            name: 'abc'
          )
          expect(event.name).to eq('abc')
        end

        it 'accepts 100 characters (maximum)' do
          name = 'a' * 100
          event = described_class.new(
            **base_params,
            name: name
          )
          expect(event.name).to eq(name)
        end

        it 'accepts 50 characters (middle)' do
          # Your test here
        end
      end
    end
  end

  describe '#duration_in_hours' do
    # let! (with bang): Eager-loaded test data
    # WHY let! vs let? Forces creation before test runs
    # USE CASE: When you need side effects (like database setup)
    let!(:event) do
      described_class.new(
        name: 'Conference',
        description: 'A conference',
        venue: Venue.new(
          name: 'Convention Center',
          address: '123 Main St',
          capacity: 1000
        ),
        start_time: Time.new(2026, 6, 15, 9, 0, 0),
        end_time: Time.new(2026, 6, 15, 17, 0, 0), # 8 hours later
        total_seats: 500
      )
    end

    it 'calculates duration in hours' do
      # WHY be_within? Floating point comparison - avoid precision issues
      expect(event.duration_in_hours).to be_within(0.01).of(8.0)
    end
  end

  describe '#to_s' do
    subject(:event) do
      described_class.new(
        name: 'RubyConf',
        description: 'Ruby Conference',
        venue: Venue.new(
          name: 'SFA',
          address: '123 Main St',
          capacity: 1000
        ),
        start_time: Time.new(2026, 6, 15, 9, 0, 0),
        end_time: Time.new(2026, 6, 15, 17, 0, 0),
        total_seats: 100
      )
    end

    it 'returns a human-readable string representation' do
      # include matcher: checks if string contains substring
      # WHY? More flexible than exact equality
      expect(event.to_s).to include('RubyConf')
      expect(event.to_s).to include('SF')
    end
  end

  describe '#sold_out?' do
    context 'when seats are available' do
      subject(:event) do
        described_class.new(
          name: 'Conference',
          description: 'A conference',
          venue: Venue.new(
            name: 'Convention Center',
            address: '123 Main St',
            capacity: 1000
          ),
          start_time: Time.now,
          end_time: Time.now + 3600,
          total_seats: 100
        )
      end

      it 'returns false when there are available seats' do
        expect(event.sold_out?).to be false
      end
    end

    context 'when no seats are available' do
      let(:event) do
        described_class.new(
          name: 'Event',
          description: 'Description',
          venue: Venue.new(
            name: 'Convention Center',
            address: '123 Main St',
            capacity: 1000
          ),
          start_time: Time.now,
          end_time: Time.now + 3600,
          total_seats: 100
        )
      end

      before do
        # TODO: You'll need a way to reduce available_seats to 0
        event.available_seats = 0
      end

      it 'returns true when there are no available seats' do
        expect(event.sold_out?).to be true
      end
    end
  end

  describe '#reserve_seats' do
    let(:event) do
      described_class.new(
        name: 'Conference',
        description: 'A conference',
        venue: Venue.new(
          name: 'Convention Center',
          address: '123 Main St',
          capacity: 1000
        ),
        start_time: Time.now,
        end_time: Time.now + 3600,
        total_seats: 100
      )
    end

    context 'when enough seats are available' do
      it 'reduces available seats by the requested amount' do
        event.reserve_seats(10)
        expect(event.available_seats).to eq(90)
      end

      it 'returns the number of seats reserved' do
        result = event.reserve_seats(10)
        expect(result).to eq(10)
      end
    end

    context 'when not enough seats are available' do
      before do
        event.reserve_seats(95) # Leave only 5 available
      end

      it 'raises an error' do
        expect { event.reserve_seats(10) }.to raise_error(
          ArgumentError,
          /not enough seats available/
        )
      end

      it 'does not modify available seats' do
        expect { event.reserve_seats(10) }.to raise_error(ArgumentError)
        expect(event.available_seats).to eq(5)
      end
    end

    context 'when requesting zero seats' do
      it 'raises an error' do
        expect { event.reserve_seats(0) }.to raise_error(
          ArgumentError,
          /must reserve at least 1 seat/
        )
      end
    end

    context 'when requesting negative seats' do
      it 'raises an error' do
        expect { event.reserve_seats(-5) }.to raise_error(
          ArgumentError,
          /must reserve at least 1 seat/
        )
      end
    end
  end
end
