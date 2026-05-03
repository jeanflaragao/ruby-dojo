# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/value_objects/date_range'

RSpec.describe DateRange do
  let(:start_date) { Date.new(2024, 1, 1) }
  let(:end_date) { Date.new(2024, 1, 31) }

  describe 'initialization' do
    it 'creates a date range' do
      range = described_class.new(start_date, end_date)
      expect(range.start_date).to eq(start_date)
      expect(range.end_date).to eq(end_date)
    end

    it 'raises error when start is after end' do
      expect do
        described_class.new(end_date, start_date)
      end.to raise_error(ArgumentError, /before/)
    end

    it 'allows same start and end (single day)' do
      range = described_class.new(start_date, start_date)
      expect(range.days).to eq(1)
    end

    it 'is frozen (immutable)' do
      range = described_class.new(start_date, end_date)
      expect(range).to be_frozen
    end
  end

  describe 'duration' do
    it 'calculates days in range (inclusive)' do
      range = described_class.new(start_date, end_date)
      expect(range.days).to eq(31)
    end

    it 'calculates weeks in range' do
      range = described_class.new(Date.new(2024, 1, 1), Date.new(2024, 1, 14))
      expect(range.weeks).to eq(2)
    end
  end

  describe 'includes?' do
    let(:range) { described_class.new(start_date, end_date) }

    it 'returns true for date within range' do
      mid_date = Date.new(2024, 1, 15)
      expect(range.includes?(mid_date)).to be true
    end

    it 'returns true for start date' do
      expect(range.includes?(start_date)).to be true
    end

    it 'returns true for end date' do
      expect(range.includes?(end_date)).to be true
    end

    it 'returns false for date before range' do
      before_date = Date.new(2023, 12, 31)
      expect(range.includes?(before_date)).to be false
    end

    it 'returns false for date after range' do
      after_date = Date.new(2024, 2, 1)
      expect(range.includes?(after_date)).to be false
    end
  end

  describe 'overlaps?' do
    let(:range) { described_class.new(Date.new(2024, 1, 10), Date.new(2024, 1, 20)) }

    it 'returns true when ranges overlap' do
      other = described_class.new(Date.new(2024, 1, 15), Date.new(2024, 1, 25))
      expect(range.overlaps?(other)).to be true
    end

    it 'returns true when one range contains another' do
      other = described_class.new(Date.new(2024, 1, 12), Date.new(2024, 1, 18))
      expect(range.overlaps?(other)).to be true
    end

    it 'returns true when ranges touch at boundary' do
      other = described_class.new(Date.new(2024, 1, 20), Date.new(2024, 1, 25))
      expect(range.overlaps?(other)).to be true
    end

    it 'returns false when ranges do not overlap' do
      other = described_class.new(Date.new(2024, 1, 21), Date.new(2024, 1, 25))
      expect(range.overlaps?(other)).to be false
    end

    it 'returns false when ranges are adjacent but not touching' do
      other = described_class.new(Date.new(2024, 1, 22), Date.new(2024, 1, 25))
      expect(range.overlaps?(other)).to be false
    end
  end

  describe 'equality' do
    it 'is equal when dates match' do
      range1 = described_class.new(start_date, end_date)
      range2 = described_class.new(start_date, end_date)
      expect(range1).to eq(range2)
    end

    it 'is not equal when dates differ' do
      range1 = described_class.new(start_date, end_date)
      range2 = described_class.new(start_date, Date.new(2024, 2, 1))
      expect(range1).not_to eq(range2)
    end
  end

  describe 'formatting' do
    it 'converts to string' do
      range = described_class.new(start_date, end_date)
      expect(range.to_s).to eq('2024-01-01 to 2024-01-31')
    end

    it 'converts to hash' do
      range = described_class.new(start_date, end_date)
      expect(range.to_h).to eq({
                                 start_date: start_date,
                                 end_date: end_date,
                                 days: 31
                               })
    end
  end
end
