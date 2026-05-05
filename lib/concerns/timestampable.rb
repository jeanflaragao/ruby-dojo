# frozen_string_literal: true

# Timestampable - Automatic timestamp tracking
#
# WHY? Every model should track when it was created/updated
# This is a standard pattern in Rails (ActiveRecord::Timestamp)
#
# USAGE:
#   class Event
#     include Timestampable
#
#     def initialize(name:)
#       @name = name
#       set_timestamps  # Call this in initialize
#     end
#
#     def save
#       touch  # Call this when updating
#     end
#   end
#
# RUBY CONCEPTS:
# - Modules can define instance variables
# - attr_reader exposed by the module
# - Callbacks (we'll use hooks in advanced version)

module Timestampable
  # Expose timestamps as readable attributes
  # WHY attr_reader here? The module adds these accessors to the class!
  attr_reader :created_at, :updated_at

  # Initialize timestamps (call in initialize)
  #
  # WHY a separate method? Can't guarantee initialize is called
  # The class that includes this must call set_timestamps explicitly
  def set_timestamps
    now = Time.now
    @created_at = now
    @updated_at = now
  end

  # Update the updated_at timestamp
  #
  # WHY "touch"? Rails convention - touches the record
  # Call this method whenever the object changes
  def touch
    @updated_at = Time.now
  end

  # Check if record is new (no created_at timestamp)
  #
  # WHY useful? Conditional logic based on persistence state
  def new_record?
    @created_at.nil?
  end

  # Check if record has been modified since creation
  #
  # WHY useful? Detect if object was updated
  def modified?
    return false if new_record?

    @updated_at > @created_at
  end

  # Get age of record in seconds
  #
  # @return [Float] seconds since creation
  def age
    return 0 if new_record?

    Time.now - @created_at
  end
end

# ============================================================================
# USAGE EXAMPLE
# ============================================================================
#
# class Event
#   include Timestampable
#
#   attr_reader :name
#
#   def initialize(name:)
#     @name = name
#     set_timestamps  # Set created_at and updated_at
#   end
#
#   def update_name(new_name)
#     @name = new_name
#     touch  # Update updated_at
#   end
# end
#
# event = Event.new(name: 'RubyConf')
# puts event.created_at  # => 2026-05-02 10:30:00
# puts event.new_record?  # => false
#
# sleep(1)
# event.update_name('RubyConf 2026')
# puts event.updated_at   # => 2026-05-02 10:30:01
# puts event.modified?    # => true
# puts event.age          # => 1.0 (seconds)
#
# ============================================================================

# ============================================================================
# ADVANCED PATTERN: Automatic timestamp updates
# ============================================================================
#
# This is a preview of what we'll build on Day 4 (Callbacks)
#
# module Timestampable
#   def self.included(base)
#     base.class_eval do
#       # Automatically call set_timestamps after initialize
#       alias_method :original_initialize, :initialize
#
#       def initialize(*args, **kwargs, &block)
#         original_initialize(*args, **kwargs, &block)
#         set_timestamps
#       end
#     end
#   end
#
#   # ... rest of the module
# end
#
# With this, you don't need to call set_timestamps manually!
# But this is metaprogramming - we'll cover it later.
# ============================================================================
