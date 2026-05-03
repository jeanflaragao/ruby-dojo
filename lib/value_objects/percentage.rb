# frozen_string_literal: true

class Percentage
  attr_reader :value

  def initialize(value)
    raise ArgumentError, 'Value must be between 0 and 1' unless (0..1).include?(value)

    @value = value
    freeze # Make immutable
  end

  def to_s
    "#{(value * 100).round(2)}%"
  end

  def ==(other)
    return false unless other.is_a?(Percentage)

    value == other.value
  end

  def of(number)
    value * number
  end

  def +(other)
    unless other.is_a?(Percentage)
      raise ArgumentError, "You can only add another Percentage object"
    end

    new_value = (self.value + other.value).round(2)

    Percentage.new(new_value)
  end

  alias eql? ==

  def hash
    value.hash
  end
end