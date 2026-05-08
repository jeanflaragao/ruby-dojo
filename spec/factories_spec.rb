# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'FactoryBot factories' do
  describe 'Event factory' do
    it 'has valid event factory' do
      event = build(:event)
      expect(event).to be_valid
    end

    it 'creates event with venue' do
      event = create(:event)
      expect(event.venue).to be_present
      expect(event).to be_persisted
    end

    it 'has correct price format' do
      event = create(:event)
      expect(event.base_price_amount).to be_a(BigDecimal)
      expect(event.base_price_currency).to eq('USD')
    end

    it 'sold_out trait sets available_seats to 0' do
      event = create(:event, :sold_out)
      expect(event.available_seats).to eq(0)
    end

    it 'past trait sets dates in past' do
      event = create(:event, :past)
      expect(event.start_time).to be < Time.current
    end

    it 'expensive trait sets higher price' do
      event = create(:event, :expensive)
      expect(event.base_price_amount).to eq(500.00)
    end

    it 'with_bookings trait creates bookings' do
      event = create(:event, :with_bookings)
      expect(event.bookings.count).to eq(5)
    end
  end

  describe 'Venue factory' do
    it 'has valid venue factory' do
      venue = build(:venue)
      expect(venue).to be_valid
    end

    it 'creates venue' do
      venue = create(:venue)
      expect(venue).to be_persisted
    end

    it 'small trait has low capacity' do
      venue = create(:venue, :small)
      expect(venue.capacity).to eq(50)
    end

    it 'large trait has high capacity' do
      venue = create(:venue, :large)
      expect(venue.capacity).to eq(5000)
    end

    it 'with_events trait creates events' do
      venue = create(:venue, :with_events)
      expect(venue.events.count).to eq(3)
    end
  end

  describe 'Booking factory' do
    it 'has valid booking factory' do
      booking = build(:booking)
      expect(booking).to be_valid
    end

    it 'creates booking with event' do
      booking = create(:booking)
      expect(booking).to be_persisted
      expect(booking.event).to be_present
    end

    it 'generates unique emails' do
      booking1 = create(:booking)
      booking2 = create(:booking)
      expect(booking1.email).not_to eq(booking2.email)
    end

    it 'generates confirmation code' do
      booking = create(:booking)
      expect(booking.confirmation_code).to be_present
    end

    it 'has correct price format' do
      booking = create(:booking)
      expect(booking.total_price_amount).to be_a(BigDecimal)
      expect(booking.total_price_currency).to eq('USD')
    end

    it 'vip trait has higher price' do
      standard = create(:booking)
      vip = create(:booking, :vip)
      expect(vip.total_price_amount).to be > standard.total_price_amount
    end

    it 'large_group trait reserves more seats' do
      booking = create(:booking, :large_group)
      expect(booking.seats_reserved).to eq(10)
    end
  end
end