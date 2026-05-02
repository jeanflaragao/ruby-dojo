# frozen_string_literal: true

# spec/venue_spec.rb
require 'spec_helper'

RSpec.describe Venue do
  describe '#initialize' do
    context 'when all required attributes are provided' do
      # 1. Define your test data using 'let'
      subject(:venue) do
        described_class.new(
          name: name,
          address: address,
          capacity: capacity
        )
      end

      let(:name) { 'Madison Square Garden' }
      let(:address) { 'New York' }
      let(:capacity) { 19_500 }

      it 'creates a venue with all attributes' do
        expect(venue.name).to eq(name)
        expect(venue.address).to eq(address)
        expect(venue.capacity).to eq(capacity)
      end
    end

    context 'when validating attributes' do
      let(:venue) { { name: 'Valid Name', address: 'Valid Address', capacity: 100 } }

      it 'raises an error for 2 characters' do
        expect do
          described_class.new(
            **venue,
            name: 'ab'
          )
        end.to raise_error(ArgumentError, /name must be at least 3 characters long/)
      end
    end
  end

  describe '#to_s' do
    subject(:venue) { described_class.new(name: 'Test Venue', address: '123 Main St', capacity: 500) }

    it 'returns a formatted string' do
      expect(venue.to_s).to eq('Venue: Test Venue at 123 Main St (Capacity: 500)')
    end
  end
end
