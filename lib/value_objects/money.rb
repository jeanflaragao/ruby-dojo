# frozen_string_literal: true

# Money value object - Immutable representation of monetary values
# Prevents primitive obsession (using raw integers for money)
#
# Example:
#   ticket_price = Money.new(50, 'USD')
#   total = ticket_price * 3  # => Money.new(150, 'USD')
class Money
  attr_reader :amount, :currency

  def initialize(amount, currency = 'USD')
    raise ArgumentError, 'Amount cannot be nil' if amount.nil?
    raise ArgumentError, 'Amount must be non-negative' unless amount >= 0

    @amount = amount
    @currency = currency
    freeze # Make immutable
  end

  # Equality based on value, not identity
  def ==(other)
    return false unless other.is_a?(Money)

    amount == other.amount && currency == other.currency
  end

  alias eql? ==

  def hash
    [amount, currency].hash
  end

  # Arithmetic operations return new Money instances
  def +(other)
    ensure_same_currency!(other)
    Money.new(amount + other.amount, currency)
  end

  def -(other)
    ensure_same_currency!(other)
    Money.new(amount - other.amount, currency)
  end

  def *(other)
    Money.new(amount * other, currency)
  end

  def /(other)
    Money.new(amount / other, currency)
  end

  # Comparison
  def <=>(other)
    ensure_same_currency!(other)
    amount <=> other.amount
  end

  include Comparable

  # Formatting
  def to_s
    format('%.2f %s', amount, currency)
  end

  def to_h
    { amount: amount, currency: currency }
  end

  private

  def ensure_same_currency!(other)
    return if currency == other.currency

    raise ArgumentError, "Currency mismatch: #{currency} vs #{other.currency}"
  end
end
