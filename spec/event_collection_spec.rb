# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventCollection do
  subject(:collection) { described_class.new([event1, event2]) }

  let(:event1) do
    Event.new(
      name: 'Event 1',
      description: 'Already happened',
      venue: Venue.new(name: 'Venue', address: 'Address', capacity: 101),
      start_time: Time.now - 86_400,  # Yesterday
      end_time: Time.now - 3600,
      total_seats: 101
    )
  end

  let(:event2) do
    Event.new(
      name: 'Event 2',
      description: 'Will happen',
      venue: Venue.new(name: 'Venue', address: 'Address', capacity: 200),
      start_time: Time.now + 86_400,  # Tomorrow
      end_time: Time.now + 90_000,
      total_seats: 200
    )
  end

  describe 'Enumerable methods' do
    it 'implements each' do
      names = collection.map(&:name)
      expect(names).to eq([event1.name, event2.name])
    end

    it 'gets map for free from Enumerable' do
      names = collection.map(&:name)
      expect(names).to eq([event1.name, event2.name])
    end

    it 'gets select for free from Enumerable' do
      # Assuming event1 has more seats than event2
      results = collection.select { |e| e.total_seats > 100 }
      expect(results).to include(event1)
    end

    it 'gets find for free from Enumerable' do
      result = collection.find { |e| e.name == event1.name }
      expect(result).to eq(event1)
    end
  end
end
