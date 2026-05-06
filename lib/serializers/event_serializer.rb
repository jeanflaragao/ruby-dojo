# frozen_string_literal: true

require_relative '../value_objects/money'

class EventSerializer
  def initialize(event)
    @event = event
  end

  def as_json(include_venue: false)
    {
      id: @event.id,
      name: @event.name,
      description: @event.description,
      start_time: @event.start_time.iso8601,
      end_time: @event.end_time.iso8601,
      total_seats: @event.total_seats,
      available_seats: @event.available_seats,
      base_price: serialize_money(@event.base_price),
      venue_id: @event.venue_id,
      created_at: @event.created_at.iso8601,
      updated_at: @event.updated_at.iso8601
    }.tap do |hash|
      hash[:venue] = VenueSerializer.new(@event.venue).as_json(include_events: false) if include_venue
    end
  end

  def self.collection(events, **options)
    events.map { |event| new(event).as_json(**options) }
  end

  private

  def serialize_money(money)
    {
      amount: format('%.2f', money.amount),
      currency: money.currency
    }
  end
end