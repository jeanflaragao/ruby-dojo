# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Timestampable do
  # Create a test class that includes Timestampable
  subject(:record) { test_class.new('Test') }

  let(:test_class) do
    Class.new do
      include Timestampable

      attr_reader :name

      def initialize(name)
        @name = name
        set_timestamps
      end

      def update(new_name)
        @name = new_name
        touch
      end
    end
  end

  describe '#set_timestamps' do
    it 'sets created_at' do
      expect(record.created_at).to be_a(Time)
    end

    it 'sets updated_at' do
      expect(record.updated_at).to be_a(Time)
    end

    it 'sets both timestamps to the same time initially' do
      expect(record.created_at).to eq(record.updated_at)
    end

    it 'sets timestamps to current time' do
      # Allow small time difference for test execution
      expect(record.created_at).to be_within(1).of(Time.now)
    end
  end

  describe '#touch' do
    it 'updates the updated_at timestamp' do
      original_updated_at = record.updated_at
      allow(Time).to receive(:now).and_return(original_updated_at + 1)
      record.touch

      expect(record.updated_at).to be > original_updated_at
    end

    it 'does not change created_at' do
      original_created_at = record.created_at
      allow(Time).to receive(:now).and_return(original_created_at + 1)
      record.touch

      expect(record.created_at).to eq(original_created_at)
    end
  end

  describe '#new_record?' do
    context 'when timestamps are set' do
      it 'returns false' do
        expect(record.new_record?).to be false
      end
    end

    context 'when timestamps are not set' do
      let(:uninitialized_record) do
        obj = test_class.allocate # Create without calling initialize
        obj
      end

      it 'returns true' do
        expect(uninitialized_record.new_record?).to be true
      end
    end
  end

  describe '#modified?' do
    context 'when record is new' do
      let(:new_record) { test_class.allocate }

      it 'returns false' do
        expect(new_record.modified?).to be false
      end
    end

    context 'when record has not been touched' do
      it 'returns false' do
        expect(record.modified?).to be false
      end
    end

    context 'when record has been touched' do
      before do
        record # ensure record is created before stubbing Time
        allow(Time).to receive(:now).and_return(record.created_at + 1)
        record.touch
      end

      it 'returns true' do
        expect(record.modified?).to be true
      end
    end

    context 'when using update method' do
      it 'detects modification' do
        allow(Time).to receive(:now).and_return(record.created_at + 1)
        record.update('New Name')

        expect(record.modified?).to be true
      end
    end
  end

  describe '#age' do
    context 'for new record' do
      let(:new_record) { test_class.allocate }

      it 'returns 0' do
        expect(new_record.age).to eq(0)
      end
    end

    context 'for existing record' do
      it 'returns time since creation' do
        allow(Time).to receive(:now).and_return(record.created_at + 0.1)
        expect(record.age).to be_within(0.05).of(0.1)
      end

      it 'increases over time' do
        age1 = record.age
        allow(Time).to receive(:now).and_return(record.created_at + 0.05)
        age2 = record.age

        expect(age2).to be > age1
      end
    end
  end

  # Integration test with real-world scenario
  describe 'integration with Event class' do
    let(:event_class) do
      Class.new do
        include Timestampable

        attr_reader :name

        def initialize(name:)
          @name = name
          set_timestamps
        end

        def update_name(new_name)
          @name = new_name
          touch
        end
      end
    end

    it 'tracks event creation time' do
      event = event_class.new(name: 'RubyConf')

      expect(event.created_at).to be_a(Time)
      expect(event.new_record?).to be false
    end

    it 'tracks event modifications' do
      event = event_class.new(name: 'RubyConf')
      initial_updated = event.updated_at
      allow(Time).to receive(:now).and_return(initial_updated + 1)
      event.update_name('RubyConf 2026')

      expect(event.updated_at).to be > initial_updated
      expect(event.modified?).to be true
    end

    it 'preserves creation time across updates' do
      event = event_class.new(name: 'RubyConf')
      creation_time = event.created_at
      allow(Time).to receive(:now).and_return(creation_time + 1)
      event.update_name('RubyConf 2026')

      expect(event.created_at).to eq(creation_time)
    end
  end
end
