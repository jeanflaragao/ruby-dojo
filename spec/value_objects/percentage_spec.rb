RSpec.describe Percentage do
  describe 'initialization' do
    it 'creates a percentage from a decimal (0.25 = 25%)' do
      percent = Percentage.new(0.25)
      expect(percent.value).to eq(0.25)
      expect(percent.to_s).to eq('25.0%')
    end
    
    it 'raises error for values < 0' do
      expect { Percentage.new(-0.1) }.to raise_error(ArgumentError)
    end
    
    it 'raises error for values > 1' do
      expect { Percentage.new(1.5) }.to raise_error(ArgumentError)
    end
  end
  
  describe 'of method' do
    it 'calculates percentage of a number' do
      percent = Percentage.new(0.2)  # 20%
      expect(percent.of(100)).to eq(20)
    end
    
    it 'calculates percentage of Money' do
      percent = Percentage.new(0.1)  # 10%
      amount = Money.new(100, 'USD')
      result = percent.of(amount.amount)
      expect(result).to eq(Money.new(10, 'USD').amount)
    end
  end
  
  describe 'arithmetic' do
    it 'adds two percentages' do
      p1 = Percentage.new(0.1)  # 10%
      p2 = Percentage.new(0.05) # 5%
      result = p1 + p2
      expect(result.value).to eq(Percentage.new(0.15).value)
    end
  end
end