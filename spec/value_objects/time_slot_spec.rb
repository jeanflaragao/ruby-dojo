RSpec.describe TimeSlot do
  describe 'initialization' do
    it 'creates a time slot with start and end time' do
      slot = TimeSlot.new(
        Time.new(2024, 1, 1, 10, 0),
        Time.new(2024, 1, 1, 11, 0)
      )
      expect(slot.start_time).to eq(Time.new(2024, 1, 1, 10, 0))
      expect(slot.duration_minutes).to eq(60)
    end
    
    it 'raises error when start is after end' do
      expect do
        TimeSlot.new(
          Time.new(2024, 1, 1, 11, 0),
          Time.new(2024, 1, 1, 10, 0)
        )
      end.to raise_error(ArgumentError, /before/)
    end
  end
  
  describe 'overlaps?' do
    let(:slot1) { TimeSlot.new(Time.new(2024, 1, 1, 10, 0), Time.new(2024, 1, 1, 11, 0)) }
    
    it 'returns true when slots overlap' do
      slot2 = TimeSlot.new(Time.new(2024, 1, 1, 10, 30), Time.new(2024, 1, 1, 11, 30))
      expect(slot1.overlaps?(slot2)).to be true
    end
    
    it 'returns false when slots do not overlap' do
      slot2 = TimeSlot.new(Time.new(2024, 1, 1, 11, 0), Time.new(2024, 1, 1, 12, 0))
      expect(slot1.overlaps?(slot2)).to be false
    end
  end
  
  describe 'formatting' do
    it 'formats with AM/PM' do
      slot = TimeSlot.new(Time.new(2024, 1, 1, 14, 0), Time.new(2024, 1, 1, 15, 30))
      expect(slot.to_s).to eq('2:00 PM - 3:30 PM')
    end
  end
end