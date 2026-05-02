# frozen_string_literal: true

class Venue
  attr_reader :name, :address, :capacity

  def initialize(name:, address:, capacity:)
    validate_required_fields(name: name, capacity: capacity)

    @name = name
    @address = address
    @capacity = capacity
  end

  def to_s
    "Venue: #{name} at #{address} (Capacity: #{capacity})"
  end

  private

  def validate_required_fields(name:, capacity:)
    raise ArgumentError, 'name is required' if name.nil? || name.empty?
    raise ArgumentError, 'name must be at least 3 characters long' if name.length < 3
    raise ArgumentError, 'capacity is required' if capacity.nil?
  end
end
