require 'spec_helper'
require_relative '../../lib/models/event'
require_relative '../../lib/models/venue'

RSpec.describe Event, type: :model do
  let(:venue) do
    Venue.create!(
      name: 'Convention Center',
      address: '123 Main St',
      capacity: 500
    )
  end

  describe 'database persistence' do
    it 'can be created with all attributes' do
      event = described_class.create!(
        name: 'RubyConf',
        description: 'Ruby conference',
        venue: venue,
        start_time: Time.now,
        end_time: Time.now + 3.hours,
        total_seats: 100,
        base_price: Money.new(50, 'USD')
      )

      expect(event).to be_persisted
      expect(event.venue).to eq(venue)
      expect(event.base_price).to eq(Money.new(50, 'USD'))
    end
  end

  describe 'associations' do
    it 'belongs to a venue' do
      event = described_class.create!(
        name: 'Concert',
        description: 'Music event',
        venue: venue,
        start_time: Time.now,
        end_time: Time.now + 2.hours,
        total_seats: 50,
        base_price: Money.new(100, 'USD')
      )

      expect(event.venue).to eq(venue)
      expect(event.venue_id).to eq(venue.id)
    end
  end

  describe 'validations' do
    it 'requires name' do
      event = described_class.new(venue: venue)
      expect(event).not_to be_valid
      expect(event.errors[:name]).to be_present
    end

    it 'validates end_time is after start_time' do
      event = described_class.new(
        name: 'Event',
        description: 'Test',
        venue: venue,
        start_time: Time.now,
        end_time: Time.now - 1.hour,  # Before start!
        total_seats: 100,
        base_price: Money.new(50, 'USD')
      )

      expect(event).not_to be_valid
      expect(event.errors[:end_time]).to include('must be after start time')
    end
  end
end