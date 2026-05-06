require 'spec_helper'
require_relative '../../lib/models/event'
require_relative '../../lib/models/venue'
require_relative '../../lib/models/booking'
require_relative '../../lib/value_objects/money'

RSpec.describe 'ActiveRecord Associations', type: :integration do
  describe 'Event -> Venue relationship' do
    it 'event belongs to venue' do
      venue = Venue.create!(name: 'Arena', address: '123 St', capacity: 5000)
      event = Event.create!(
        name: 'Concert',
        description: 'Live music event',
        venue: venue,  # ← Association magic!
        start_time: Time.now + 86400,
        end_time: Time.now + 90000,
        total_seats: 100,
        available_seats: 100,
        base_price: Money.new(5000, 'USD')
      )
      
      expect(event.venue).to eq(venue)
      expect(event.venue.name).to eq('Arena')
    end
    
    it 'venue has many events' do
      venue = Venue.create!(name: 'Theater', address: '456 Ave', capacity: 200)
      
      event1 = Event.create!(
        name: 'Play 1',
        description: 'Drama play',
        venue: venue,
        start_time: Time.now + 86400,
        end_time: Time.now + 90000,
        total_seats: 50,
        available_seats: 50,
        base_price: Money.new(3000, 'USD')
      )
      
      event2 = Event.create!(
        name: 'Play 2',
        description: 'Comedy play',
        venue: venue,
        start_time: Time.now + 172800,
        end_time: Time.now + 176400,
        total_seats: 50,
        available_seats: 50,
        base_price: Money.new(3500, 'USD')
      )
      
      expect(venue.events.count).to eq(2)
      expect(venue.events).to include(event1, event2)
    end
  end
  
  describe 'Event -> Bookings relationship' do
    let(:venue) { Venue.create!(name: 'Hall', address: '789 Blvd', capacity: 1000) }
    let(:event) do
      Event.create!(
        name: 'Conference',
        description: 'Tech conference',
        venue: venue,
        start_time: Time.now + 86400,
        end_time: Time.now + 90000,
        total_seats: 200,
        available_seats: 200,
        base_price: Money.new(10000, 'USD')
      )
    end
    
    it 'event has many bookings' do
      booking1 = Booking.create!(
        event: event,
        email: 'user1@test.com',
        seats_reserved: 2,
        ticket_type: 'general',
        total_price: Money.new(20000, 'USD')
      )
      
      booking2 = Booking.create!(
        event: event,
        email: 'user2@test.com',
        seats_reserved: 1,
        ticket_type: 'vip',
        total_price: Money.new(15000, 'USD')
      )
      
      expect(event.bookings.count).to eq(2)
      expect(event.bookings).to include(booking1, booking2)
    end
    
    it 'booking belongs to event' do
      booking = Booking.create!(
        event: event,
        email: 'customer@test.com',
        seats_reserved: 5,
        ticket_type: 'student',
        total_price: Money.new(25000, 'USD')
      )
      
      expect(booking.event).to eq(event)
      expect(booking.event.name).to eq('Conference')
    end
    
    it 'deleting event deletes associated bookings (dependent: :destroy)' do
      Booking.create!(
        event: event,
        email: 'temp@test.com',
        seats_reserved: 1,
        ticket_type: 'general',
        total_price: Money.new(10000, 'USD')
      )
      
      expect { event.destroy }.to change { Booking.count }.by(-1)
    end
  end
  
  describe 'Scopes' do
    let(:venue) { Venue.create!(name: 'Park', address: 'Outside', capacity: 500) }
    
    it 'finds upcoming events only' do
      past_event = Event.create!(
        name: 'Old Concert',
        description: 'Past event',
        venue: venue,
        start_time: Time.now - 86400,
        end_time: Time.now - 82800,
        total_seats: 100,
        available_seats: 0,
        base_price: Money.new(5000, 'USD')
      )
      
      future_event = Event.create!(
        name: 'New Concert',
        description: 'Future event',
        venue: venue,
        start_time: Time.now + 86400,
        end_time: Time.now + 90000,
        total_seats: 100,
        available_seats: 50,
        base_price: Money.new(6000, 'USD')
      )
      
      upcoming = Event.upcoming
      expect(upcoming).to include(future_event)
      expect(upcoming).not_to include(past_event)
    end
    
    it 'finds available events only' do
      sold_out = Event.create!(
        name: 'Sold Out Show',
        description: 'No seats left',
        venue: venue,
        start_time: Time.now + 86400,
        end_time: Time.now + 90000,
        total_seats: 50,
        available_seats: 0,  # ← Sold out!
        base_price: Money.new(8000, 'USD')
      )
      
      available = Event.create!(
        name: 'Available Show',
        description: 'Seats available',
        venue: venue,
        start_time: Time.now + 172800,
        end_time: Time.now + 176400,
        total_seats: 50,
        available_seats: 30,  # ← Has seats!
        base_price: Money.new(7000, 'USD')
      )
      
      available_events = Event.available
      expect(available_events).to include(available)
      expect(available_events).not_to include(sold_out)
    end
    
    it 'can chain scopes' do
      Event.create!(
        name: 'Sold Out Future',
        description: 'No seats left',
        venue: venue,
        start_time: Time.now + 86400,
        end_time: Time.now + 90000,
        total_seats: 50,
        available_seats: 0,
        base_price: Money.new(5000, 'USD')
      )
      
      available_upcoming = Event.create!(
        name: 'Available Future',
        description: 'Seats available',
        venue: venue,
        start_time: Time.now + 172800,
        end_time: Time.now + 176400,
        total_seats: 50,
        available_seats: 20,
        base_price: Money.new(6000, 'USD')
      )
      
      # Chain scopes together!
      results = Event.upcoming.available
      expect(results).to include(available_upcoming)
      expect(results.count).to eq(1)
    end
  end
end