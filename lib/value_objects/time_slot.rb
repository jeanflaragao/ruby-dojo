# frozen_string_literal: true

class TimeSlot
  attr_reader :start_time, :end_time

  def initialize(start_time, end_time)
    raise ArgumentError, 'Start time must be before end time' if start_time >= end_time

    @start_time = start_time
    @end_time = end_time
    freeze
  end

  def duration_minutes
    ((end_time - start_time) / 60).to_i
  end

  def overlaps?(other)
    start_time < other.end_time && end_time > other.start_time
  end

  def ==(other)
    return false unless other.is_a?(TimeSlot)

    start_time == other.start_time && end_time == other.end_time
  end

  alias eql? ==

  def hash
    [start_time, end_time].hash
  end

  def to_s
    "#{start_time.strftime('%-I:%M %p')} - #{end_time.strftime('%-I:%M %p')}"
  end

  def to_h
    {
      start_time: start_time,
      end_time: end_time
    }
  end
end
