# db/seeds.rb

require_relative '../lib/models/booking'
require_relative '../lib/models/event'
require_relative '../lib/models/venue'

puts "🧹 Cleaning up existing database..."
Booking.destroy_all
Event.destroy_all
Venue.destroy_all

puts "🏗️ Creating Venues..."
venue = Venue.create!(
  name: 'Convention Center',
  address: '123 Main St',
  capacity: 500
)

puts "📅 Creating Events..."
event1 = Event.create!(
  name: 'RubyConf',
  description: 'Ruby conference',
  venue: venue,
  start_time: Time.now + 1.day,
  end_time: Time.now + 1.day + 8.hours,
  total_seats: 100,
  base_price_amount: 50.00,
  base_price_currency: 'USD'
)

puts "🎟️ Creating a test Booking..."
puts "event_id: #{event1.id}"

Booking.create!(
  email: 'seed_tester@example.com',
  seats_reserved: 2,
  total_price_amount: 100.00,
  total_price_currency: 'USD',
  ticket_type: 'general',
  event_id: event1.id 
)

puts "✅ Seed finished successfully! 🌱"