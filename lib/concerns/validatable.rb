# frozen_string_literal: true

# Validatable - Shared validation logic
#
# WHY? Both Event and Venue validate names the same way
# DRY PRINCIPLE: Don't Repeat Yourself
#
# USAGE:
#   class Event
#     include Validatable
#
#     def initialize(name:)
#       validate_name(name)
#     end
#   end
#
# RUBY CONCEPT: Mixin
# - Include this module to get validation methods
# - No inheritance needed
# - Can be mixed into multiple classes

module Validatable
  # Validate name is present and within length bounds
  #
  # @param name [String] the name to validate
  # @param min [Integer] minimum length (default: 3)
  # @param max [Integer] maximum length (default: 100)
  # @raise [ArgumentError] if validation fails
  #
  # WHY keyword arguments? Flexible, self-documenting
  # WHY defaults? Most names should be 3-100 characters
  def validate_name(name, min: 3, max: 100)
    validate_presence(name, field_name: 'name')
    validate_length(name, min: min, max: max, field_name: 'name')
  end

  # Validate field is not nil or empty
  #
  # @param value [Object] the value to check
  # @param field_name [String] name of the field for error message
  # @raise [ArgumentError] if nil or empty
  def validate_presence(value, field_name: 'field')
    if value.nil?
      raise ArgumentError, "#{field_name} is required"
    elsif value.respond_to?(:empty?) && value.empty?
      raise ArgumentError, "#{field_name} is required"
    end
  end

  # Validate string length is within bounds
  #
  # @param value [String] the string to validate
  # @param min [Integer] minimum length
  # @param max [Integer] maximum length
  # @param field_name [String] name of the field for error message
  # @raise [ArgumentError] if length invalid
  #
  # WHY respond_to? Check if object has length method (duck typing!)
  def validate_length(value, min:, max:, field_name: 'field')
    raise ArgumentError, "#{field_name} must respond to length" unless value.respond_to?(:length)

    if value.length < min
      raise ArgumentError, "#{field_name} must be at least #{min} characters long"
    elsif value.length > max
      raise ArgumentError, "#{field_name} must be at most #{max} characters long"
    end
  end

  # Validate number is positive
  #
  # @param value [Numeric] the number to validate
  # @param field_name [String] name of the field for error message
  # @raise [ArgumentError] if not positive
  #
  # WHY positive? Common business rule - seats, capacity, price > 0
  def validate_positive(value, field_name: 'field')
    raise ArgumentError, "#{field_name} must be a number" unless value.respond_to?(:positive?)

    return if value.positive?

    raise ArgumentError, "#{field_name} must be positive"
  end

  # Validate number is within range
  #
  # @param value [Numeric] the number to validate
  # @param min [Numeric] minimum value (inclusive)
  # @param max [Numeric] maximum value (inclusive)
  # @param field_name [String] name of the field for error message
  # @raise [ArgumentError] if out of range
  def validate_range(value, min:, max:, field_name: 'field')
    raise ArgumentError, "#{field_name} must be a number" unless value.respond_to?(:between?)

    return if value.between?(min, max)

    raise ArgumentError, "#{field_name} must be between #{min} and #{max}"
  end

  # Validate time ordering (end after start)
  #
  # @param start_time [Time] the start time
  # @param end_time [Time] the end time
  # @raise [ArgumentError] if end_time <= start_time
  #
  # WHY this validation? Business rule - events can't end before they start
  def validate_time_order(start_time, end_time)
    raise ArgumentError, 'times must be comparable' unless start_time.respond_to?(:<) && end_time.respond_to?(:>)

    return unless end_time <= start_time

    raise ArgumentError, 'end_time must be after start_time'
  end
end

# ============================================================================
# USAGE NOTES
# ============================================================================
#
# BEFORE (with duplication):
#
#   class Event
#     def validate_required_fields(name:)
#       raise ArgumentError, 'name is required' if name.nil? || name.empty?
#       raise ArgumentError, 'name must be at least 3 characters' if name.length < 3
#     end
#   end
#
#   class Venue
#     def validate_required_fields(name:)
#       raise ArgumentError, 'name is required' if name.nil? || name.empty?
#       raise ArgumentError, 'name must be at least 3 characters' if name.length < 3
#     end
#   end
#
# AFTER (with module):
#
#   class Event
#     include Validatable
#
#     def validate_required_fields(name:)
#       validate_name(name)  # Uses module method!
#     end
#   end
#
#   class Venue
#     include Validatable
#
#     def validate_required_fields(name:)
#       validate_name(name)  # Same module method!
#     end
#   end
#
# BENEFITS:
# - No duplication
# - Consistent validation logic
# - Easy to test (test module once)
# - Easy to extend (add new validation methods)
# ============================================================================
