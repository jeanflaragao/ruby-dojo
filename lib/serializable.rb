# frozen_string_literal: true

# lib/serializable.rb
require 'json'

module Serializable
  def to_json(*)
    attributes = self.class.serializable_attributes
    hash = attributes.each_with_object({}) do |attr, h|
      value = send(attr)
      h[attr] = serialize_value(value)
    end
    hash.to_json(*)
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def serializable_attributes(*attrs)
      @serializable_attributes = attrs if attrs.any?
      @serializable_attributes || []
    end

    def from_json(json_string)
      hash = JSON.parse(json_string, symbolize_names: true)
      new(**hash)
    end
  end

  private

  def serialize_value(value)
    case value
    when Time
      value.iso8601
    when Venue, Event
      value.to_json # Nested objects
    else
      value
    end
  end
end
