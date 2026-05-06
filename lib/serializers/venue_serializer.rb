# frozen_string_literal: true

class VenueSerializer
  def initialize(venue)
    @venue = venue
  end

  def as_json(include_events: false)
    {
      id: @venue.id,
      name: @venue.name,
      address: @venue.address,
      capacity: @venue.capacity,
      created_at: @venue.created_at.iso8601,
      updated_at: @venue.updated_at.iso8601
    }.tap do |hash|
      if include_events
        # Lazy load EventSerializer to avoid circular dependency
        require_relative 'event_serializer' unless defined?(EventSerializer)
        hash[:events] = EventSerializer.collection(@venue.events, include_venue: false)
      end
    end
  end

  def self.collection(venues, **options)
    venues.map { |venue| new(venue).as_json(**options) }
  end
end