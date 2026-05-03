# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Result do
  describe '.success' do
    it 'creates a Success object' do
      result = described_class.success('value')
      expect(result).to be_a(Success)
    end

    it 'stores the value' do
      result = described_class.success('test value')
      expect(result.value).to eq('test value')
    end

    it 'works with nil value' do
      result = described_class.success(nil)
      expect(result.value).to be_nil
    end
  end

  describe '.failure' do
    it 'creates a Failure object' do
      result = described_class.failure('error')
      expect(result).to be_a(Failure)
    end

    it 'stores the error' do
      result = described_class.failure('error message')
      expect(result.error).to eq('error message')
    end
  end
end

RSpec.describe Success do
  subject(:success) { described_class.new('success value') }

  describe '#success?' do
    it 'returns true' do
      expect(success.success?).to be true
    end
  end

  describe '#failure?' do
    it 'returns false' do
      expect(success.failure?).to be false
    end
  end

  describe '#value' do
    it 'returns the stored value' do
      expect(success.value).to eq('success value')
    end
  end

  describe '#on_success' do
    it 'executes the block with value' do
      executed = false
      result_value = nil

      success.on_success do |value|
        executed = true
        result_value = value
      end

      expect(executed).to be true
      expect(result_value).to eq('success value')
    end

    it 'returns self for chaining' do
      result = success.on_success { |_v| }
      expect(result).to eq(success)
    end
  end

  describe '#on_failure' do
    it 'does not execute the block' do
      executed = false
      success.on_failure { executed = true }
      expect(executed).to be false
    end

    it 'returns self for chaining' do
      result = success.on_failure { |_e| }
      expect(result).to eq(success)
    end
  end

  describe '#map' do
    it 'transforms the value' do
      result = success.map(&:upcase)
      expect(result).to be_success
      expect(result.value).to eq('SUCCESS VALUE')
    end

    it 'returns self without block' do
      result = success.map
      expect(result).to eq(success)
    end

    it 'can chain multiple maps' do
      result = described_class.new(10)
                              .map { |n| n * 2 }
                              .map { |n| n + 5 }

      expect(result.value).to eq(25)
    end
  end

  describe '#flat_map' do
    it 'unwraps nested Results' do
      result = success.flat_map { |_v| Result.success('new value') }

      expect(result).to be_success
      expect(result.value).to eq('new value')
    end

    it 'preserves failures in chain' do
      result = success.flat_map { |_v| Result.failure('error') }

      expect(result).to be_failure
      expect(result.error).to eq('error')
    end
  end

  describe '#value_or' do
    it 'returns the value, ignoring default' do
      expect(success.value_or('default')).to eq('success value')
    end
  end

  describe '#to_s' do
    it 'shows the value' do
      expect(success.to_s).to eq('Success("success value")')
    end
  end
end

RSpec.describe Failure do
  subject(:failure) { described_class.new('error message') }

  describe '#success?' do
    it 'returns false' do
      expect(failure.success?).to be false
    end
  end

  describe '#failure?' do
    it 'returns true' do
      expect(failure.failure?).to be true
    end
  end

  describe '#error' do
    it 'returns the stored error' do
      expect(failure.error).to eq('error message')
    end
  end

  describe '#on_success' do
    it 'does not execute the block' do
      executed = false
      failure.on_success { executed = true }
      expect(executed).to be false
    end

    it 'returns self for chaining' do
      result = failure.on_success { |_v| }
      expect(result).to eq(failure)
    end
  end

  describe '#on_failure' do
    it 'executes the block with error' do
      executed = false
      result_error = nil

      failure.on_failure do |error|
        executed = true
        result_error = error
      end

      expect(executed).to be true
      expect(result_error).to eq('error message')
    end

    it 'returns self for chaining' do
      result = failure.on_failure { |_e| }
      expect(result).to eq(failure)
    end
  end

  describe '#map' do
    it 'does not transform on failure' do
      result = failure.map(&:upcase)
      expect(result).to eq(failure)
    end
  end

  describe '#flat_map' do
    it 'does not execute on failure' do
      result = failure.flat_map { |_v| Result.success('ignored') }
      expect(result).to eq(failure)
    end
  end

  describe '#value_or' do
    it 'returns the default value' do
      expect(failure.value_or('default')).to eq('default')
    end
  end

  describe '#to_s' do
    it 'shows the error' do
      expect(failure.to_s).to eq('Failure("error message")')
    end
  end
end

RSpec.describe 'Railway-Oriented Programming' do
  def validate(number)
    number.positive? ? Result.success(number) : Result.failure('must be positive')
  end

  def double(number)
    Result.success(number * 2)
  end

  def add_five(number)
    Result.success(number + 5)
  end

  it 'chains successful operations' do
    result = validate(10)
             .flat_map { |n| double(n) }
             .flat_map { |n|               add_five(n) }

    expect(result).to be_success
    expect(result.value).to eq(25) # (10 * 2) + 5
  end

  it 'short-circuits on first failure' do
    result = validate(-5) # Fails here
             .flat_map { |n| double(n) } # Skipped
             .flat_map { |n|               add_five(n) } # Skipped

    expect(result).to be_failure
    expect(result.error).to eq('must be positive')
  end

  it 'allows branching with on_success/on_failure' do
    success_executed = false
    failure_executed = false

    Result.success('value')
          .on_success { success_executed = true }
          .on_failure { failure_executed = true }

    expect(success_executed).to be true
    expect(failure_executed).to be false
  end

  it 'executes both success and failure handlers in chain' do
    log = []

    Result.failure('error')
          .on_success { |v| log << "Success: #{v}" }
          .on_failure { |e| log << "Failure: #{e}" }

    expect(log).to eq(['Failure: error'])
  end
end
