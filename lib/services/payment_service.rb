class PaymentService
  # Payment result data
  Payment = Struct.new(:transaction_id, :amount, :status, :timestamp)
  
  def charge(amount, payment_method)
    validate_amount(amount)
      .flat_map { validate_payment_method(payment_method) }
      .flat_map { process_payment(amount, payment_method) }
  end
  
  private
  
  def validate_amount(amount)
    if amount <= 0
      Result.failure('Amount must be positive')
    elsif amount > 10000
      Result.failure('Amount exceeds maximum allowed')
    else
      Result.success(amount)
    end
  end
  
  def validate_payment_method(method)
    if method.nil? || method.empty?
      return Result.failure('Payment method is required')
    end
    
    Result.success(method)
  end
  
  def process_payment(amount, method)
    # Simulate payment processing
    if rand < 0.1  # 10% chance of failure
      Result.failure('Payment declined by bank')
    else
      payment = Payment.new(
        generate_transaction_id,
        amount,
        'succeeded',
        Time.now
      )
      Result.success(payment)
    end
  end
  
  def generate_transaction_id
    "TXN-#{Time.now.to_i}-#{rand(1000..9999)}"
  end
end