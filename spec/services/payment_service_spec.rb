# frozen_string_literal: true

RSpec.describe PaymentService do
  subject(:service) { described_class.new }

  describe '#charge' do
    context 'when payment succeeds' do
      before do
        # This forces `rand` to always return 0.5 when called inside `service`
        allow(service).to receive(:rand).and_return(0.5)
      end

      it 'returns Success with payment' do
        result = service.charge(100.0, 'credit_card')

        expect(result).to be_success
        payment = result.value
        expect(payment.amount).to eq(100.0)
        expect(payment.status).to eq('succeeded')
      end
    end

    context 'when amount is invalid' do
      it 'returns Failure for zero amount' do
        result = service.charge(0, 'credit_card')

        expect(result).to be_failure
        expect(result.error).to include('positive')
      end

      it 'returns Failure for negative amount' do
        result = service.charge(-50, 'credit_card')

        expect(result).to be_failure
      end

      it 'returns Failure for amount over limit' do
        result = service.charge(20_000, 'credit_card')

        expect(result).to be_failure
        expect(result.error).to include('exceeds maximum')
      end
    end

    context 'when payment method is invalid' do
      it 'returns Failure for nil payment method' do
        result = service.charge(100.0, nil)

        expect(result).to be_failure
        expect(result.error).to include('Payment method')
      end

      it 'returns Failure for empty payment method' do
        # Your test here
      end
    end

    context 'railway pattern' do
      it 'chains validation and processing' do
        # Verify that validation happens before processing
      end

      it 'short-circuits on first failure' do
        result = service.charge(-10, 'invalid')
        # Should fail at amount validation, never reach payment method validation
        expect(result.error).to include('Amount')
      end
    end
  end
end
