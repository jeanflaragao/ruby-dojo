# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/serializers/event_serializer'

RSpec.describe EventSerializer do
  let(:venue) do
    Venue.create!(
      name: 'Convention Center',
      address: '123 Main St',
      capacity: 500
    )
  end

  let(:event) do
    Event.create!(
      name: 'RubyConf 2026',
      description: 'Annual Ruby conference',
      venue: venue,
      start_time: Time.new(2026, 6, 15, 9, 0, 0),
      end_time: Time.new(2026, 6, 15, 17, 0, 0),
      total_seats: 500,
      base_price: Money.new(50, 'USD')
    )
  end

  describe '#as_json' do
    it 'serializes basic event attributes' do
      serializer = described_class.new(event)
      json = serializer.as_json

      expect(json).to include(
        id: event.id,
        name: 'RubyConf 2026',
        description: 'Annual Ruby conference',
        total_seats: 500,
        available_seats: 500
      )
    end

    it 'serializes Money value object' do
      serializer = described_class.new(event)
      json = serializer.as_json

      expect(json[:base_price]).to eq(
        amount: '50.00',
        currency: 'USD'
      )
    end

    it 'serializes timestamps in ISO8601 format' do
      serializer = described_class.new(event)
      json = serializer.as_json

      expect(json[:start_time]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      expect(json[:created_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    it 'includes venue when requested' do
      serializer = described_class.new(event)
      json = serializer.as_json(include_venue: true)

      expect(json[:venue]).to include(
        id: venue.id,
        name: 'Convention Center',
        address: '123 Main St',
        capacity: 500
      )
    end

    it 'excludes venue when not requested' do
      serializer = described_class.new(event)
      json = serializer.as_json(include_venue: false)

      expect(json).not_to have_key(:venue)
    end
  end

  describe '.collection' do
    it 'serializes array of events' do
      event2 = Event.create!(
        name: 'RailsConf 2026',
        description: 'Rails conference',
        venue: venue,
        start_time: Time.new(2026, 7, 20, 9, 0, 0),
        end_time: Time.new(2026, 7, 20, 17, 0, 0),
        total_seats: 300,
        base_price: Money.new(75, 'USD')
      )

      json = described_class.collection([event, event2])

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.first[:name]).to eq('RubyConf 2026')
      expect(json.second[:name]).to eq('RailsConf 2026')
    end
  end
end