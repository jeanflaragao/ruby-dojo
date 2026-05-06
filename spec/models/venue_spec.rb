# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/models/venue'

RSpec.describe Venue, type: :model do
  describe 'database persistence' do
    it 'can be created and saved to database' do
      venue = described_class.create!(
        name: 'Convention Center',
        address: '123 Main St',
        capacity: 500
      )

      expect(venue).to be_persisted
      expect(venue.id).not_to be_nil
      expect(described_class.count).to eq(1)
    end

    it 'can be found by id' do
      venue = described_class.create!(name: 'Theater', address: '456 Oak Ave', capacity: 200)
      found = described_class.find(venue.id)

      expect(found.name).to eq('Theater')
    end
  end

  describe 'validations' do
    it 'requires name' do
      venue = described_class.new(address: '123 Main', capacity: 100)
      expect(venue).not_to be_valid
      expect(venue.errors[:name]).to include("can't be blank")
    end

    it 'requires capacity to be positive' do
      venue = described_class.new(name: 'Place', address: '123 Main', capacity: -5)
      expect(venue).not_to be_valid
      expect(venue.errors[:capacity]).to include('must be greater than 0')
    end
  end
end