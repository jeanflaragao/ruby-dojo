# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Searchable do
  subject(:repository) { test_class.new([event1, event2]) }

  let(:test_class) do
    Class.new do
      include Searchable

      attr_reader :events

      def initialize(events)
        @events = events
      end
    end
  end

  let(:event1) do
    Event.new(
      name: 'RubyConf',
      description: 'Ruby conference',
      venue: Venue.new(
        name: 'Convention Center',
        address: 'San Francisco',
        capacity: 1000
      ),
      start_time: Time.now - 86_400,  # Yesterday
      end_time: Time.now - 3600,
      total_seats: 1000
    )
  end

  let(:event2) do
    Event.new(
      name: 'RailsConf',
      description: 'Rails conference',
      venue: Venue.new(
        name: 'Rails Center',
        address: 'San Francisco',
        capacity: 1000
      ),
      start_time: Time.now - 86_400,  # Yesterday
      end_time: Time.now - 3600,
      total_seats: 1000
    )
  end

  describe '#search_by' do
    it 'finds by name' do
      results = repository.search_by(:name, 'Ruby')
      expect(results).to contain_exactly(event1)
    end

    it 'is case-insensitive' do
      results = repository.search_by(:name, 'ruby')
      expect(results).to contain_exactly(event1)
    end

    it 'finds by description' do
      results = repository.search_by(:description, 'conference')
      expect(results).to contain_exactly(event1, event2)
    end
  end

  describe '#search_across' do
    it 'searches multiple attributes' do
      results = repository.search_across('Ruby', :name, :description)
      expect(results).to include(event1)
    end
  end
end
