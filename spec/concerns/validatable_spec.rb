# frozen_string_literal: true

require 'spec_helper'

# Testing a module directly
# WHY? Modules should be tested in isolation before mixing into classes
#
# APPROACH: Create a dummy class that includes the module
# This is a common pattern for testing mixins

RSpec.describe Validatable do
  # Create a test class that includes the module
  # WHY a new class? Need something to include the module into
  # Create an instance of the test class
  subject(:validator) { test_class.new }

  let(:test_class) do
    Class.new do
      include Validatable
    end
  end

  describe '#validate_name' do
    context 'when name is valid' do
      it 'does not raise error for valid name' do
        expect { validator.validate_name('RubyConf') }.not_to raise_error
      end

      it 'accepts minimum length name' do
        expect { validator.validate_name('ABC') }.not_to raise_error
      end

      it 'accepts maximum length name' do
        name = 'a' * 100
        expect { validator.validate_name(name) }.not_to raise_error
      end

      it 'accepts custom min/max' do
        expect { validator.validate_name('Hi', min: 2, max: 10) }.not_to raise_error
      end
    end

    context 'when name is invalid' do
      it 'raises error for nil name' do
        expect { validator.validate_name(nil) }.to raise_error(ArgumentError, /name is required/)
      end

      it 'raises error for empty name' do
        expect { validator.validate_name('') }.to raise_error(ArgumentError, /name is required/)
      end

      it 'raises error for name too short' do
        expect { validator.validate_name('AB') }.to raise_error(ArgumentError, /at least 3 characters/)
      end

      it 'raises error for name too long' do
        name = 'a' * 101
        expect { validator.validate_name(name) }.to raise_error(ArgumentError, /at most 100 characters/)
      end
    end
  end

  describe '#validate_presence' do
    it 'does not raise error for present value' do
      expect { validator.validate_presence('value') }.not_to raise_error
    end

    it 'raises error for nil' do
      expect { validator.validate_presence(nil) }.to raise_error(ArgumentError, /field is required/)
    end

    it 'raises error for empty string' do
      expect { validator.validate_presence('') }.to raise_error(ArgumentError, /field is required/)
    end

    it 'raises error for empty array' do
      expect { validator.validate_presence([]) }.to raise_error(ArgumentError, /field is required/)
    end

    it 'uses custom field name in error' do
      expect do
        validator.validate_presence(nil, field_name: 'email')
      end.to raise_error(ArgumentError, /email is required/)
    end
  end

  describe '#validate_length' do
    it 'validates string within bounds' do
      expect { validator.validate_length('hello', min: 3, max: 10) }.not_to raise_error
    end

    it 'accepts minimum length' do
      expect { validator.validate_length('abc', min: 3, max: 10) }.not_to raise_error
    end

    it 'accepts maximum length' do
      expect { validator.validate_length('1234567890', min: 3, max: 10) }.not_to raise_error
    end

    it 'raises error for too short' do
      expect do
        validator.validate_length('ab', min: 3, max: 10)
      end.to raise_error(ArgumentError, /at least 3 characters/)
    end

    it 'raises error for too long' do
      expect do
        validator.validate_length('12345678901', min: 3, max: 10)
      end.to raise_error(ArgumentError, /at most 10 characters/)
    end

    it 'raises error for non-string' do
      expect do
        validator.validate_length(123, min: 1, max: 5)
      end.to raise_error(ArgumentError, /must respond to length/)
    end

    it 'uses custom field name in error' do
      expect do
        validator.validate_length('a', min: 3, max: 10, field_name: 'username')
      end.to raise_error(ArgumentError, /username must be at least/)
    end
  end

  describe '#validate_positive' do
    it 'accepts positive number' do
      expect { validator.validate_positive(10) }.not_to raise_error
    end

    it 'accepts positive float' do
      expect { validator.validate_positive(0.1) }.not_to raise_error
    end

    it 'raises error for zero' do
      expect { validator.validate_positive(0) }.to raise_error(ArgumentError, /must be positive/)
    end

    it 'raises error for negative' do
      expect { validator.validate_positive(-5) }.to raise_error(ArgumentError, /must be positive/)
    end

    it 'raises error for non-number' do
      expect { validator.validate_positive('10') }.to raise_error(ArgumentError, /must be a number/)
    end

    it 'uses custom field name' do
      expect do
        validator.validate_positive(0, field_name: 'price')
      end.to raise_error(ArgumentError, /price must be positive/)
    end
  end

  describe '#validate_range' do
    it 'accepts value within range' do
      expect { validator.validate_range(5, min: 1, max: 10) }.not_to raise_error
    end

    it 'accepts minimum value' do
      expect { validator.validate_range(1, min: 1, max: 10) }.not_to raise_error
    end

    it 'accepts maximum value' do
      expect { validator.validate_range(10, min: 1, max: 10) }.not_to raise_error
    end

    it 'raises error for below minimum' do
      expect do
        validator.validate_range(0, min: 1, max: 10)
      end.to raise_error(ArgumentError, /must be between 1 and 10/)
    end

    it 'raises error for above maximum' do
      expect do
        validator.validate_range(11, min: 1, max: 10)
      end.to raise_error(ArgumentError, /must be between 1 and 10/)
    end
  end

  describe '#validate_time_order' do
    let(:start_time) { Time.new(2026, 6, 15, 9, 0, 0) }
    let(:end_time) { Time.new(2026, 6, 15, 17, 0, 0) }

    it 'accepts end after start' do
      expect { validator.validate_time_order(start_time, end_time) }.not_to raise_error
    end

    it 'raises error for end before start' do
      expect do
        validator.validate_time_order(end_time, start_time)
      end.to raise_error(ArgumentError, /end_time must be after start_time/)
    end

    it 'raises error for same time' do
      expect do
        validator.validate_time_order(start_time, start_time)
      end.to raise_error(ArgumentError, /end_time must be after start_time/)
    end
  end

  # Testing that module can be included in classes
  describe 'integration with classes' do
    let(:event_class) do
      Class.new do
        include Validatable

        attr_reader :name

        def initialize(name)
          validate_name(name)
          @name = name
        end
      end
    end

    it 'works when mixed into a class' do
      event = event_class.new('RubyConf 2026')
      expect(event.name).to eq('RubyConf 2026')
    end

    it 'validates when mixed into a class' do
      expect { event_class.new('AB') }.to raise_error(ArgumentError)
    end
  end
end
