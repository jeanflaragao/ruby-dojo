# frozen_string_literal: true

RSpec.describe Address do
  describe 'initialization' do
    it 'creates an address with street, city, state, zip' do
      address = described_class.new(
        street: '123 Main St',
        city: 'San Francisco',
        state: 'CA',
        zip: '94102'
      )
      expect(address.street).to eq('123 Main St')
      expect(address.city).to eq('San Francisco')
    end

    it 'is frozen (immutable)' do
      address = described_class.new(street: '123 Main St', city: 'SF', state: 'CA', zip: '94102')
      expect(address).to be_frozen
    end

    it 'requires all fields' do
      expect { described_class.new(street: '123 Main St', city: 'SF') }
        .to raise_error(ArgumentError)
    end
  end

  describe 'equality' do
    it 'is equal when all fields match' do
      addr1 = described_class.new(street: '123 Main', city: 'SF', state: 'CA', zip: '94102')
      addr2 = described_class.new(street: '123 Main', city: 'SF', state: 'CA', zip: '94102')
      expect(addr1).to eq(addr2)
    end
  end

  describe 'formatting' do
    it 'formats as single line' do
      address = described_class.new(street: '123 Main St', city: 'SF', state: 'CA', zip: '94102')
      expect(address.to_s).to eq('123 Main St, SF, CA 94102')
    end
  end
end
