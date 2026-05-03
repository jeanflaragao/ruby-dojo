# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/value_objects/money'

RSpec.describe Money do
  describe 'initialization' do
    it 'creates money with amount and currency' do
      money = described_class.new(100, 'USD')
      expect(money.amount).to eq(100)
      expect(money.currency).to eq('USD')
    end

    it 'defaults to USD if currency not specified' do
      money = described_class.new(100)
      expect(money.currency).to eq('USD')
    end

    it 'raises error for negative amounts' do
      expect { described_class.new(-100, 'USD') }.to raise_error(ArgumentError, /non-negative/)
    end

    it 'raises error for nil amount' do
      expect { described_class.new(nil, 'USD') }.to raise_error(ArgumentError)
    end

    it 'is frozen (immutable)' do
      money = described_class.new(100, 'USD')
      expect(money).to be_frozen
    end
  end

  describe 'equality' do
    it 'is equal when amount and currency match' do
      money1 = described_class.new(100, 'USD')
      money2 = described_class.new(100, 'USD')
      expect(money1).to eq(money2)
    end

    it 'is not equal when amounts differ' do
      money1 = described_class.new(100, 'USD')
      money2 = described_class.new(200, 'USD')
      expect(money1).not_to eq(money2)
    end

    it 'is not equal when currencies differ' do
      money1 = described_class.new(100, 'USD')
      money2 = described_class.new(100, 'EUR')
      expect(money1).not_to eq(money2)
    end

    it 'can be used as hash key' do
      money = described_class.new(100, 'USD')
      hash = { money => 'ticket_price' }
      expect(hash[described_class.new(100, 'USD')]).to eq('ticket_price')
    end
  end

  describe 'arithmetic' do
    let(:money1) { described_class.new(100, 'USD') }
    let(:money2) { described_class.new(50, 'USD') }

    describe 'addition' do
      it 'adds two money objects' do
        result = money1 + money2
        expect(result).to eq(described_class.new(150, 'USD'))
      end

      it 'returns a new object (immutability)' do
        original = described_class.new(100, 'USD')
        result = original + money2
        expect(original.amount).to eq(100)
        expect(result).not_to equal(original)
      end

      it 'raises error for currency mismatch' do
        eur_money = described_class.new(50, 'EUR')
        expect { money1 + eur_money }.to raise_error(ArgumentError, /mismatch/)
      end
    end

    describe 'subtraction' do
      it 'subtracts two money objects' do
        result = money1 - money2
        expect(result).to eq(described_class.new(50, 'USD'))
      end

      it 'raises error for currency mismatch' do
        eur_money = described_class.new(50, 'EUR')
        expect { money1 - eur_money }.to raise_error(ArgumentError, /mismatch/)
      end
    end

    describe 'multiplication' do
      it 'multiplies by a number' do
        result = money1 * 3
        expect(result).to eq(described_class.new(300, 'USD'))
      end

      it 'preserves currency' do
        result = money1 * 2
        expect(result.currency).to eq('USD')
      end
    end

    describe 'division' do
      it 'divides by a number' do
        result = money1 / 2
        expect(result).to eq(described_class.new(50, 'USD'))
      end
    end
  end

  describe 'comparison' do
    it 'compares money values' do
      small = described_class.new(50, 'USD')
      large = described_class.new(100, 'USD')

      expect(small < large).to be true
      expect(large > small).to be true
      expect(small <= large).to be true
      expect(large >= small).to be true
    end

    it 'raises error when comparing different currencies' do
      usd = described_class.new(100, 'USD')
      eur = described_class.new(100, 'EUR')
      expect { usd < eur }.to raise_error(ArgumentError, /mismatch/)
    end
  end

  describe 'formatting' do
    it 'converts to string with 2 decimal places' do
      money = described_class.new(100.5, 'USD')
      expect(money.to_s).to eq('100.50 USD')
    end

    it 'converts to hash' do
      money = described_class.new(100, 'USD')
      expect(money.to_h).to eq({ amount: 100, currency: 'USD' })
    end
  end
end
