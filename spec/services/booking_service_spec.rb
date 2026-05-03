# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BookingService do
  subject(:service) { described_class.new(repository) }

  # Create test data
  let(:venue) do
    Venue.new(
      name: 'Convention Center',
      address: '123 Main St',
      capacity: 500
    )
  end

  let(:event) do
    Event.new(
      name: 'RubyConf 2026',
      description: 'Ruby conference',
      venue: venue,
      start_time: Time.new(2026, 6, 15, 9, 0, 0),
      end_time: Time.new(2026, 6, 17, 18, 0, 0),
      total_seats: 100
    )
  end

  let(:sold_out_event) do
    event = Event.new(
      name: 'Sold Out Event',
      description: 'No seats left',
      venue: venue,
      start_time: Time.new(2026, 7, 1, 9, 0, 0),
      end_time: Time.new(2026, 7, 1, 17, 0, 0),
      total_seats: 10
    )
    event.reserve_seats(10) # Reserve all seats
    event
  end

  let(:repository) { EventRepository.new([event, sold_out_event]) }

  describe '#book (Result pattern)' do
    context 'when booking succeeds' do
      it 'returns Success with booking' do
        result = service.book('RubyConf 2026', 5)

        expect(result).to be_success
      end

      it 'includes booking details' do
        result = service.book('RubyConf 2026', 5)
        booking = result.value

        expect(booking.event).to eq(event)
        expect(booking.seats_reserved).to eq(5)
        expect(booking.total_price).to eq(250.0) # 5 * $50
        expect(booking.booking_id).to match(/BOOK-/)
        expect(booking.timestamp).to be_a(Time)
      end

      it 'reserves the seats on the event' do
        initial_available = event.available_seats

        service.book('RubyConf 2026', 5)

        expect(event.available_seats).to eq(initial_available - 5)
      end

      it 'generates unique booking IDs' do
        result1 = service.book('RubyConf 2026', 5)
        result2 = service.book('RubyConf 2026', 5)

        expect(result1.value.booking_id).not_to eq(result2.value.booking_id)
      end
    end

    context 'when validation fails' do
      it 'returns Failure for nil event name' do
        result = service.book(nil, 5)

        expect(result).to be_failure
        expect(result.error).to include('Event name is required')
      end

      it 'returns Failure for empty event name' do
        result = service.book('', 5)

        expect(result).to be_failure
        expect(result.error).to include('Event name is required')
      end

      it 'returns Failure for non-integer seats' do
        result = service.book('RubyConf 2026', '5')

        expect(result).to be_failure
        expect(result.error).to include('positive integer')
      end

      it 'returns Failure for zero seats' do
        result = service.book('RubyConf 2026', 0)

        expect(result).to be_failure
        expect(result.error).to include('positive integer')
      end

      it 'returns Failure for negative seats' do
        result = service.book('RubyConf 2026', -5)

        expect(result).to be_failure
        expect(result.error).to include('positive integer')
      end
    end

    context 'when event is not found' do
      it 'returns Failure' do
        result = service.book('NonExistent Event', 5)

        expect(result).to be_failure
        expect(result.error).to include('not found')
        expect(result.error).to include('NonExistent Event')
      end
    end

    context 'when event is sold out' do
      it 'returns Failure' do
        result = service.book('Sold Out Event', 5)

        expect(result).to be_failure
        expect(result.error).to include('sold out')
      end

      it 'does not modify event seats' do
        initial_available = sold_out_event.available_seats

        service.book('Sold Out Event', 5)

        expect(sold_out_event.available_seats).to eq(initial_available)
      end
    end

    context 'when insufficient seats available' do
      it 'returns Failure' do
        result = service.book('RubyConf 2026', 150) # More than 100 available

        expect(result).to be_failure
        expect(result.error).to include('Only')
        expect(result.error).to include('100')
        expect(result.error).to include('150')
      end

      it 'does not modify event seats' do
        initial_available = event.available_seats

        service.book('RubyConf 2026', 150)

        expect(event.available_seats).to eq(initial_available)
      end
    end

    context 'railway-oriented programming' do
      it 'chains successful operations' do
        result = service.book('RubyConf 2026', 5)

        expect(result).to be_success
      end

      it 'short-circuits on first failure' do
        # First failure is "event not found"
        # Should not check seats or reserve
        result = service.book('NonExistent', 5)

        expect(result).to be_failure
        expect(result.error).to include('not found')
      end

      it 'allows branching with on_success/on_failure' do
        success_executed = false
        failure_executed = false

        service.book('RubyConf 2026', 5)
               .on_success { |_booking| success_executed = true }
               .on_failure { |_error| failure_executed = true }

        expect(success_executed).to be true
        expect(failure_executed).to be false
      end
    end
  end

  describe '#book! (Exception pattern)' do
    context 'when booking succeeds' do
      it 'returns the booking' do
        booking = service.book!('RubyConf 2026', 5)

        expect(booking).to be_a(BookingService::Booking)
        expect(booking.seats_reserved).to eq(5)
      end
    end

    context 'when event not found' do
      it 'raises EventNotFoundError' do
        expect do
          service.book!('NonExistent Event', 5)
        end.to raise_error(EventNotFoundError, /NonExistent Event/)
      end

      it 'error includes event name' do
        service.book!('Missing Event', 5)
      rescue EventNotFoundError => e
        expect(e.resource_type).to eq('Event')
        expect(e.identifier).to match(/Missing Event/)
      end
    end

    context 'when event is sold out' do
      it 'raises EventSoldOutError' do
        expect do
          service.book!('Sold Out Event', 5)
        end.to raise_error(EventSoldOutError, /sold out/)
      end

      it 'error includes event name' do
        service.book!('Sold Out Event', 5)
      rescue EventSoldOutError => e
        expect(e.event_name).to match(/Sold Out Event/)
      end
    end

    context 'when insufficient seats' do
      it 'raises InsufficientSeatsError' do
        expect do
          service.book!('RubyConf 2026', 150)
        end.to raise_error(InsufficientSeatsError)
      end

      it 'error includes available and requested counts' do
        service.book!('RubyConf 2026', 150)
      rescue InsufficientSeatsError => e
        expect(e.available).to eq(100)
        expect(e.requested).to eq(150)
      end
    end

    context 'when validation fails' do
      it 'raises InvalidBookingError' do
        expect do
          service.book!('', 5)
        end.to raise_error(InvalidBookingError)
      end
    end

    context 'error hierarchy' do
      it 'allows catching all booking errors' do
        service.book!('Sold Out Event', 5)
      rescue BookingError => e
        expect(e).to be_a(EventSoldOutError)
      end

      it 'allows catching all ticketing errors' do
        service.book!('NonExistent', 5)
      rescue TicketingError => e
        expect(e).to be_a(EventNotFoundError)
      end
    end
  end

  describe 'integration with repository' do
    it 'uses injected repository to find events' do
      # Test that we're actually using the repository
      expect(repository).to receive(:find_by_name).with('RubyConf 2026').and_call_original

      service.book('RubyConf 2026', 5)
    end

    it 'works with empty repository' do
      empty_repo = EventRepository.new([])
      empty_service = described_class.new(empty_repo)

      result = empty_service.book('Any Event', 5)

      expect(result).to be_failure
      expect(result.error).to include('not found')
    end
  end

  describe 'BookingService::Booking' do
    let(:booking) do
      described_class::Booking.new(
        event,
        5,
        250.0,
        'BOOK-123',
        Time.now
      )
    end

    it 'converts to hash' do
      hash = booking.to_h

      expect(hash[:booking_id]).to eq('BOOK-123')
      expect(hash[:event_name]).to eq('RubyConf 2026')
      expect(hash[:seats_reserved]).to eq(5)
      expect(hash[:total_price]).to eq(250.0)
      expect(hash[:timestamp]).to be_a(Time)
    end
  end

  describe '#book_with_retry' do
    context 'when booking succeeds on first try' do
      it 'returns the booking' do
        booking = service.book_with_retry('RubyConf 2026', 5)
        expect(booking).to be_a(BookingService::Booking)
      end

      it 'does not retry' do
        expect(service).to receive(:book!).once.and_call_original
        service.book_with_retry('RubyConf 2026', 5)
      end
    end

    context 'when booking fails transiently' do
      it 'retries up to max_retries times' do
        # Simulate: fail, fail, succeed
        allow(service).to receive(:book!)
          .and_raise(InvalidBookingError.new('temporary'))
          .and_raise(InvalidBookingError.new('temporary'))
          .and_return(double(booking_id: 'BOOK-123'))

        result = service.book_with_retry('RubyConf 2026', 5, max_retries: 3)
        expect(result.booking_id).to eq('BOOK-123')
      end
    end

    context 'when booking fails permanently' do
      it 'does not retry InsufficientSeatsError' do
        allow(service).to receive(:book!)
          .and_raise(InsufficientSeatsError.new(5, 10))

        expect do
          service.book_with_retry('RubyConf 2026', 10, max_retries: 3)
        end.to raise_error(InsufficientSeatsError)
      end
    end

    context 'when all retries exhausted' do
      it 'raises the last error' do
        allow(service).to receive(:book!)
          .and_raise(InvalidBookingError.new('error'))

        expect do
          service.book_with_retry('RubyConf 2026', 5, max_retries: 2)
        end.to raise_error(InvalidBookingError)
      end
    end
  end

  describe GuestUser do
    subject(:guest) { described_class.new }

    it 'has default guest values' do
      expect(guest.name).to eq('Guest')
      expect(guest.email).to eq('guest@example.com')
      expect(guest.role).to eq('guest')
    end

    it 'is not an admin' do
      expect(guest.admin?).to be false
    end

    it 'is a guest' do
      expect(guest.guest?).to be true
    end

    it 'has no discount' do
      expect(guest.discount_percentage).to eq(0)
    end

    it 'is polymorphic with User' do
      # Should respond to same methods as User
      expect(guest).to respond_to(:email)
      expect(guest).to respond_to(:name)
      expect(guest).to respond_to(:admin?)
      expect(guest).to respond_to(:discount_percentage)
    end
  end

  describe 'BookingService with users' do
    it 'calculates price for guest user' do
      guest = GuestUser.new
      price = service.calculate_price_for_user(guest, 100.0)
      expect(price).to be_success
      expect(price.value).to eq(100.0) # No discount
    end

    it 'calculates price for VIP user' do
      vip = User.new(email: 'vip@example.com', name: 'VIP', role: 'vip')
      price = service.calculate_price_for_user(vip, 100.0)
      expect(price).to be_success
      expect(price.value).to eq(80.0) # 20% discount
    end
  end
end
