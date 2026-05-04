# frozen_string_literal: true

class Discount
  # Factory methods for different discount types
  def self.percentage(percent)
    raise ArgumentError, 'Percentage must be between 0 and 100' if percent < 0 || percent > 100

    new(type: :percentage, value: percent)
  end

  def self.fixed(amount)
    new(type: :fixed, value: amount.amount)
  end

  def self.bulk(buy:, get:)
    new(type: :bulk, value: { buy: buy, get: get })
  end

  attr_reader :type, :value

  def initialize(type:, value:)
    @type = type
    @value = value
  end

  def apply(price, quantity: 1)
    case type
    when :percentage
      price * (1 - (value / 100.0))
    when :fixed
      Money.new([price.amount - value, 0].max, price.currency)
    when :bulk
      sets = quantity / (value[:buy] + value[:get])
      paid_items = quantity - (sets * value[:get])
      price * paid_items
    when :composed
      value.reduce(price) { |acc, discount| discount.apply(acc) }
    else
      price
    end
  end

  def then(other)
    self.class.new(type: :composed, value: [self, other])
  end
end
