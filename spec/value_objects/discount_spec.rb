# frozen_string_literal: true

RSpec.describe Discount do
  describe 'percentage discount' do
    it 'applies percentage discount' do
      discount = described_class.percentage(20) # 20% off
      price = Money.new(100, 'USD')

      result = discount.apply(price)
      expect(result).to eq(Money.new(80, 'USD'))
    end
  end

  describe 'fixed amount discount' do
    it 'applies fixed amount discount' do
      discount = described_class.fixed(Money.new(15, 'USD'))
      price = Money.new(100, 'USD')

      result = discount.apply(price)
      expect(result).to eq(Money.new(85, 'USD'))
    end

    it 'does not go below zero' do
      discount = described_class.fixed(Money.new(150, 'USD'))
      price = Money.new(100, 'USD')

      result = discount.apply(price)
      expect(result).to eq(Money.new(0, 'USD'))
    end
  end

  describe 'buy X get Y free' do
    it 'applies bulk discount' do
      discount = described_class.bulk(buy: 2, get: 1) # Buy 2, get 1 free
      price = Money.new(100, 'USD')

      # 3 items: pay for 2
      result = discount.apply(price, quantity: 3)
      expect(result).to eq(Money.new(200, 'USD'))

      # 6 items: pay for 4
      result = discount.apply(price, quantity: 6)
      expect(result).to eq(Money.new(400, 'USD'))
    end
  end

  describe 'combination' do
    it 'can combine multiple discounts' do
      d1 = described_class.percentage(10) # 10% off
      d2 = described_class.fixed(Money.new(5, 'USD'))

      combined = d1.then(d2)
      price = Money.new(100, 'USD')

      # Apply 10% first: 100 → 90
      # Then $5 off: 90 → 85
      result = combined.apply(price)
      expect(result).to eq(Money.new(85, 'USD'))
    end
  end
end
