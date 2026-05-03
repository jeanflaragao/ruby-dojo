# frozen_string_literal: true

RSpec.describe EventForm do
  describe 'validation' do
    it 'is valid with all required fields' do
      form = described_class.new(
        name: 'Ruby Conference',
        description: 'Annual Ruby event',
        venue_name: 'Convention Center',
        start_time: '2024-06-01 10:00',
        end_time: '2024-06-01 18:00',
        total_seats: '500',
        base_price: '100'
      )
      expect(form).to be_valid
    end

    it 'requires event name' do
      form = described_class.new(description: 'Event')
      expect(form).not_to be_valid
      expect(form.errors[:name]).to include("can't be blank")
    end

    it 'validates start_time is before end_time' do
      form = described_class.new(
        name: 'Event',
        description: 'Test',
        venue_name: 'Venue',
        start_time: '2024-06-01 18:00',
        end_time: '2024-06-01 10:00', # After start!
        total_seats: '100',
        base_price: '50'
      )
      expect(form).not_to be_valid
      expect(form.errors[:end_time]).to include('must be after start time')
    end

    it 'validates total_seats is positive' do
      form = described_class.new(
        name: 'Event',
        description: 'Test',
        venue_name: 'Venue',
        start_time: '2024-06-01 10:00',
        end_time: '2024-06-01 18:00',
        total_seats: '0',
        base_price: '50'
      )
      expect(form).not_to be_valid
      expect(form.errors[:total_seats]).to include('must be positive')
    end

    it 'validates base_price is positive' do
      form = described_class.new(
        name: 'Event',
        description: 'Test',
        venue_name: 'Venue',
        start_time: '2024-06-01 10:00',
        end_time: '2024-06-01 18:00',
        total_seats: '100',
        base_price: '-10'
      )
      expect(form).not_to be_valid
      expect(form.errors[:base_price]).to include('must be positive')
    end
  end

  describe '#to_h' do
    it 'coerces string dates to Time objects' do
      form = described_class.new(
        name: 'Event',
        description: 'Test',
        venue_name: 'Venue',
        start_time: '2024-06-01 10:00',
        end_time: '2024-06-01 18:00',
        total_seats: '100',
        base_price: '50'
      )

      result = form.to_h
      expect(result[:start_time]).to be_a(Time)
      expect(result[:total_seats]).to be_a(Integer)
      expect(result[:base_price]).to be_a(Money) # Coerce to Money!
    end
  end
end
