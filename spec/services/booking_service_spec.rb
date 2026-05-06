# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BookingService do
  subject(:service) { described_class.new }

  # Create test data
  let!(:venue) do
    Venue.create!(
      name: 'Convention Center',
      address: '123 Main St',
      capacity: 500
    )
  end

  let(:event_name) { 'RubyConf 2026' }

  let!(:event) do
    Event.create!(
      name: event_name,
      description: 'Ruby conference',
      venue: venue,
      start_time: Time.new(2026, 6, 15, 9, 0, 0),
      end_time: Time.new(2026, 6, 17, 18, 0, 0),
      total_seats: 100
    )
  end

  let!(:sold_out_event) do
    event = Event.create!(
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

  describe '#book (Result pattern)' do
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
      it 'short-circuits on first failure' do
        # First failure is "event not found"
        # Should not check seats or reserve
        result = service.book('NonExistent', 5)

        expect(result).to be_failure
        expect(result.error).to include('not found')
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

  describe '#book_with_form' do
    it 'books tickets using form object and value objects' do
      # Setup
      base_price = Money.new(100, 'USD')
      event = Event.create!(
        name: 'Conference',
        description: 'Tech conference',
        venue: venue,
        start_time: Time.new(2026, 8, 1, 9, 0, 0),
        end_time: Time.new(2026, 8, 1, 17, 0, 0),
        total_seats: 50,
        base_price: base_price
      )

      # Form
      form = BookingForm.new(
        event_name: 'Conference',
        seats: '2',
        ticket_type: 'vip',
        email: 'user@example.com'
      )

      # Book
      result = service.book_with_form(form)

      # Verify
      expect(result).to be_success
      booking = result.value
      expect(booking.total_price).to eq(Money.new(400, 'USD')) # 2 VIP @ $200 each
      expect(booking.ticket_type).to eq('vip')
    end
  end

  describe 'with booking repository' do
    let(:event) do
      Event.create!(
        name: 'Conference',
        description: 'A test event',
        venue: Venue.new(name: 'Test Venue', address: '123 Main St', capacity: 100),
        start_time: Time.new(2026, 6, 1),
        end_time: Time.new(2026, 6, 2),
        total_seats: 100,
        base_price: Money.new(100, 'USD')
      )
    end
    let(:service) { described_class.new }

    it 'stores bookings in repository' do
      form = BookingForm.new(
        event_name: 'Conference',
        seats: '2',
        ticket_type: 'vip',
        email: 'user@example.com'
      )
      service.book_with_form(form)

      expect(Booking.all.size).to eq(1)
    end

    it 'retrieves booking history by email' do
      form = BookingForm.new(
        event_name: 'Conference',
        seats: '2',
        ticket_type: 'vip',
        email: 'user@example.com'
      )
      service.book_with_form(form)

      history = service.booking_history('user@example.com')
      expect(history.size).to eq(1)
    end
  end
end
