# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BookingRepository do
  let(:event) { double('Event', name: 'RubyConf') }
  let(:booking) do
    BookingService::Booking.new(
      event,
      5,
      Money.new(250, 'USD'),
      'BOOK-123',
      Time.now,
      VIPTicket.new(Money.new(50, 'USD')),
      'user@example.com'
    )
  end

  describe '#add' do
    it 'stores a booking' do
      repo = described_class.new
      repo.add(booking)

      expect(repo.all).to include(booking)
    end
  end

  describe '#find_by_id' do
    it 'finds booking by ID' do
      repo = described_class.new
      repo.add(booking)

      found = repo.find_by_id('BOOK-123')
      expect(found).to eq(booking)
    end

    it 'returns nil if not found' do
      repo = described_class.new
      expect(repo.find_by_id('INVALID')).to be_nil
    end
  end

  describe '#find_by_email' do
    it 'finds all bookings for an email' do
      booking1 = BookingService::Booking.new(
        event: event,
        seats_reserved: 5,
        total_price: Money.new(250, 'USD'),
        booking_id: 'BOOK-123',
        timestamp: Time.now,
        ticket_type: VIPTicket.new(Money.new(50, 'USD')),
        email: 'user@example.com'
      )
      booking2 = BookingService::Booking.new(
        event: event,
        seats_reserved: 5,
        total_price: Money.new(250, 'USD'),
        booking_id: 'BOOK-234',
        timestamp: Time.now,
        ticket_type: VIPTicket.new(Money.new(50, 'USD')),
        email: 'user@example.com'
      )
      booking3 = BookingService::Booking.new(
        event: event,
        seats_reserved: 5,
        total_price: Money.new(250, 'USD'),
        booking_id: 'BOOK-123',
        timestamp: Time.now,
        ticket_type: VIPTicket.new(Money.new(50, 'USD')),
        email: 'other@example.com'
      )

      repo = described_class.new
      repo.add(booking1)
      repo.add(booking2)
      repo.add(booking3)

      results = repo.find_by_email('user@example.com')

      expect(results).to include(booking1, booking2)
      expect(results).not_to include(booking3)
    end
  end

  describe '#total_revenue' do
    it 'sums all booking prices' do
      b1 = BookingService::Booking.new(
        event: event,
        seats_reserved: 5,
        total_price: Money.new(100, 'USD'),
        booking_id: 'BOOK-123',
        timestamp: Time.now,
        ticket_type: VIPTicket.new(Money.new(50, 'USD')),
        email: 'user@example.com'
      )
      b2 = BookingService::Booking.new(
        event: event,
        seats_reserved: 5,
        total_price: Money.new(200, 'USD'),
        booking_id: 'BOOK-234',
        timestamp: Time.now,
        ticket_type: VIPTicket.new(Money.new(50, 'USD')),
        email: 'user@example.com'
      )

      repo = described_class.new
      repo.add(b1)
      repo.add(b2)

      expect(repo.total_revenue).to eq(Money.new(300, 'USD'))
    end
  end
end
