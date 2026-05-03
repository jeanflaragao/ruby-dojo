# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Custom Exceptions' do
  describe TicketingError do
    it 'inherits from StandardError' do
      expect(described_class.new('test')).to be_a(StandardError)
    end

    it 'stores details hash' do
      error = described_class.new('message', { key: 'value' })
      expect(error.details).to eq({ key: 'value' })
    end

    it 'converts to hash' do
      error = described_class.new('test message', { detail: 'info' })
      hash = error.to_h

      expect(hash[:error]).to eq('TicketingError')
      expect(hash[:message]).to eq('test message')
      expect(hash[:details]).to eq({ detail: 'info' })
    end
  end

  describe EventSoldOutError do
    subject(:error) { described_class.new('RubyConf 2026') }

    it 'inherits from BookingError' do
      expect(error).to be_a(BookingError)
    end

    it 'stores event name' do
      expect(error.event_name).to eq('RubyConf 2026')
    end

    it 'has descriptive message' do
      expect(error.message).to include('RubyConf 2026')
      expect(error.message).to include('sold out')
    end

    it 'includes details in to_h' do
      hash = error.to_h
      expect(hash[:details][:event]).to eq('RubyConf 2026')
      expect(hash[:details][:available_seats]).to eq(0)
    end
  end

  describe InsufficientSeatsError do
    subject(:error) { described_class.new(5, 10) }

    it 'inherits from BookingError' do
      expect(error).to be_a(BookingError)
    end

    it 'stores available and requested counts' do
      expect(error.available).to eq(5)
      expect(error.requested).to eq(10)
    end

    it 'has descriptive message' do
      expect(error.message).to include('5')
      expect(error.message).to include('10')
      expect(error.message).to include('available')
    end

    it 'optionally includes event name' do
      error_with_name = described_class.new(5, 10, event_name: 'RubyConf')
      expect(error_with_name.message).to include('RubyConf')
    end

    it 'includes details' do
      hash = error.to_h
      expect(hash[:details][:available]).to eq(5)
      expect(hash[:details][:requested]).to eq(10)
    end
  end

  describe InvalidBookingError do
    subject(:error) { described_class.new('Event in the past') }

    it 'inherits from BookingError' do
      expect(error).to be_a(BookingError)
    end

    it 'has descriptive message' do
      expect(error.message).to include('Invalid booking')
      expect(error.message).to include('Event in the past')
    end

    it 'includes reason in details' do
      expect(error.details[:reason]).to eq('Event in the past')
    end
  end

  describe ValidationError do
    subject(:error) { described_class.new('email', 'is invalid') }

    it 'inherits from TicketingError' do
      expect(error).to be_a(TicketingError)
    end

    it 'stores field name' do
      expect(error.field).to eq('email')
    end

    it 'has descriptive message' do
      expect(error.message).to include('email')
      expect(error.message).to include('is invalid')
    end
  end

  describe EventNotFoundError do
    subject(:error) { described_class.new('event-123') }

    it 'inherits from NotFoundError' do
      expect(error).to be_a(NotFoundError)
    end

    it 'stores resource type and identifier' do
      expect(error.resource_type).to eq('Event')
      expect(error.identifier).to eq('event-123')
    end

    it 'has descriptive message' do
      expect(error.message).to include('Event')
      expect(error.message).to include('event-123')
      expect(error.message).to include('not found')
    end
  end

  describe 'exception hierarchy' do
    it 'allows catching all booking errors' do
      raise InsufficientSeatsError.new(5, 10)
    rescue BookingError => e
      expect(e).to be_a(InsufficientSeatsError)
    end

    it 'allows catching all app errors' do
      raise EventNotFoundError, 'event-123'
    rescue TicketingError => e
      expect(e).to be_a(EventNotFoundError)
    end

    it 'does not catch system errors as TicketingError' do
      expect do
        raise SystemExit
      rescue TicketingError
        # Should not catch
      end.to raise_error(SystemExit)
    end
  end
end
