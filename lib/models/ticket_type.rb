# frozen_string_literal: true

require_relative '../value_objects/money'

# Base class for ticket types
# Uses Template Method pattern - subclasses define multiplier and perks
#
# Why inheritance here? TicketType represents a natural type hierarchy
# where all tickets share the same interface but differ in pricing/perks.
# This is an acceptable use of inheritance (unlike business logic).
class TicketType
  attr_reader :base_price

  def initialize(base_price = nil)
    raise NotImplementedError, 'TicketType is abstract' if instance_of?(TicketType)

    @base_price = base_price
    freeze
  end

  # Template method - subclasses override price_multiplier
  def price
    base_price * price_multiplier
  end

  # Abstract methods - must be implemented by subclasses
  def tier
    raise NotImplementedError, 'Subclass must implement #tier'
  end

  def perks
    raise NotImplementedError, 'Subclass must implement #perks'
  end

  def price_multiplier
    raise NotImplementedError, 'Subclass must implement #price_multiplier'
  end

  # Hook method - subclasses can override
  def requires_verification?
    false
  end

  # Formatting
  def to_h
    {
      tier: tier,
      price: price.to_h,
      perks: perks,
      requires_verification: requires_verification?
    }
  end

  def to_s
    "#{tier.to_s.capitalize} Ticket - #{price}"
  end
end

# VIP tickets - Premium pricing with exclusive perks
class VIPTicket < TicketType
  def tier
    :vip
  end

  def price_multiplier
    2.0
  end

  def perks
    [
      'Priority seating',
      'Meet & greet access',
      'Complimentary drinks',
      'Exclusive VIP lounge'
    ]
  end
end

# General admission tickets - Standard pricing
class GeneralTicket < TicketType
  def tier
    :general
  end

  def price_multiplier
    1.0
  end

  def perks
    ['Standard seating']
  end
end

# Student tickets - Discounted pricing with verification required
class StudentTicket < TicketType
  def tier
    :student
  end

  def price_multiplier
    0.7 # 30% discount
  end

  def perks
    [
      'Student discount (30% off)',
      'Valid student ID required'
    ]
  end

  def requires_verification?
    true
  end
end