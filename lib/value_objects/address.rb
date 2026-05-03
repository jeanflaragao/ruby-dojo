# frozen_string_literal: true

class Address
  attr_reader :street, :city, :state, :zip

  def initialize(street:, city:, state:, zip:)
    @street = street
    @city = city
    @state = state
    @zip = zip
    freeze
  end

  # Equality based on all fields
  def ==(other)
    return false unless other.is_a?(Address)

    street == other.street &&
      city == other.city &&
      state == other.state &&
      zip == other.zip
  end

  alias eql? ==

  def hash
    [street, city, state, zip].hash
  end

  # Formatting
  def to_s
    "#{street}, #{city}, #{state} #{zip}"
  end

  def to_h
    {
      street: street,
      city: city,
      state: state,
      zip: zip
    }
  end
end