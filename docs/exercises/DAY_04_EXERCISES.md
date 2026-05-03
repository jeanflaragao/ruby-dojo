# Day 4 Practical Exercises

Complete these exercises to master error handling, Result objects, and service patterns. Follow TDD - write tests first!

---

## Exercise 1: Add Retry Logic to BookingService (MEDIUM)

**Goal:** Handle transient failures with automatic retries

### Requirements

Add a `book_with_retry` method that automatically retries failed bookings.

### Implementation

```ruby
# In lib/services/booking_service.rb

def book_with_retry(event_name, requested_seats, max_retries: 3)
  attempt = 0

  begin
    attempt += 1
    book!(event_name, requested_seats)
  rescue InsufficientSeatsError => e
    # Don't retry - this is a permanent failure
    raise
  rescue BookingError => e
    if attempt < max_retries
      sleep(0.1 * attempt)  # Exponential backoff
      retry
    else
      raise
    end
  end
end
```

### Tests to Write

```ruby
# spec/services/booking_service_spec.rb

describe '#book_with_retry' do
  context 'when booking succeeds on first try' do
    it 'returns the booking' do
      booking = service.book_with_retry('RubyConf 2026', 5)
      expect(booking).to be_a(BookingService::Booking)
    end

    it 'does not retry' do
      expect(service).to receive(:book!).once.and_call_original
      service.book_with_retry('RubyConf 2026', 5)
    end
  end

  context 'when booking fails transiently' do
    it 'retries up to max_retries times' do
      # Simulate: fail, fail, succeed
      allow(service).to receive(:book!)
        .and_raise(InvalidBookingError.new('temporary'))
        .and_raise(InvalidBookingError.new('temporary'))
        .and_return(double(booking_id: 'BOOK-123'))

      result = service.book_with_retry('RubyConf 2026', 5, max_retries: 3)
      expect(result.booking_id).to eq('BOOK-123')
    end
  end

  context 'when booking fails permanently' do
    it 'does not retry InsufficientSeatsError' do
      allow(service).to receive(:book!)
        .and_raise(InsufficientSeatsError.new(5, 10))

      expect do
        service.book_with_retry('RubyConf 2026', 10, max_retries: 3)
      end.to raise_error(InsufficientSeatsError)
    end
  end

  context 'when all retries exhausted' do
    it 'raises the last error' do
      allow(service).to receive(:book!)
        .and_raise(InvalidBookingError.new('error'))

      expect do
        service.book_with_retry('RubyConf 2026', 5, max_retries: 2)
      end.to raise_error(InvalidBookingError)
    end
  end
end
```

### Questions to Think About

1. Which errors should be retried? Which shouldn't?
2. How long should we wait between retries?
3. Should max_retries be configurable?
4. How would you log retry attempts?

---

## Exercise 2: Create PaymentResult with Success/Failure (MEDIUM)

**Goal:** Practice Result pattern with payment processing

### Requirements

Create a `PaymentService` that processes payments and returns Result objects.

### Classes to Create

```ruby
# lib/services/payment_service.rb

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
    # Your implementation here
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
```

### Tests to Write

```ruby
# spec/services/payment_service_spec.rb

RSpec.describe PaymentService do
  subject(:service) { described_class.new }

  describe '#charge' do
    context 'when payment succeeds' do
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
        result = service.charge(20000, 'credit_card')

        expect(result).to be_failure
        expect(result.error).to include('exceeds maximum')
      end
    end

    context 'when payment method is invalid' do
      it 'returns Failure for nil payment method' do
        # Your test here
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
```

### Integration with BookingService

```ruby
# Extend BookingService to use PaymentService

def book_with_payment(event_name, seats, payment_method)
  book(event_name, seats)
    .flat_map { |booking| charge_payment(booking, payment_method) }
    .flat_map { |booking| finalize_booking(booking) }
end

private

def charge_payment(booking, payment_method)
  payment_service = PaymentService.new
  payment_result = payment_service.charge(booking.total_price, payment_method)

  if payment_result.success?
    Result.success(booking)
  else
    # Refund seats
    booking.event.reserve_seats(-booking.seats_reserved)
    Result.failure("Payment failed: #{payment_result.error}")
  end
end
```

---

## Exercise 3: Implement Null Object Pattern (EASY)

**Goal:** Avoid nil checks with Null Objects

### Requirements

Create a `GuestUser` class that represents a non-logged-in user.

### Classes to Create

```ruby
# lib/models/user.rb

class User
  attr_reader :email, :name, :role

  def initialize(email:, name:, role: 'customer')
    @email = email
    @name = name
    @role = role
  end

  def admin?
    role == 'admin'
  end

  def guest?
    false
  end

  def discount_percentage
    case role
    when 'admin' then 100
    when 'vip' then 20
    else 0
    end
  end
end

# lib/models/guest_user.rb

class GuestUser
  def email
    'guest@example.com'
  end

  def name
    'Guest'
  end

  def role
    'guest'
  end

  def admin?
    false
  end

  def guest?
    true
  end

  def discount_percentage
    0
  end
end
```

### Usage in BookingService

```ruby
# Before (with nil checks):
def calculate_price_for_user(user, base_price)
  if user.nil?
    base_price
  else
    discount = user.discount_percentage
    base_price * (1 - discount / 100.0)
  end
end

# After (with Null Object):
def calculate_price_for_user(user, base_price)
  # No nil check needed!
  discount = user.discount_percentage
  base_price * (1 - discount / 100.0)
end

# Usage:
user = current_user || GuestUser.new
price = calculate_price_for_user(user, 100.0)
```

### Tests to Write

```ruby
describe GuestUser do
  subject(:guest) { described_class.new }

  it 'has default guest values' do
    expect(guest.name).to eq('Guest')
    expect(guest.email).to eq('guest@example.com')
    expect(guest.role).to eq('guest')
  end

  it 'is not an admin' do
    expect(guest.admin?).to be false
  end

  it 'is a guest' do
    expect(guest.guest?).to be true
  end

  it 'has no discount' do
    expect(guest.discount_percentage).to eq(0)
  end

  it 'is polymorphic with User' do
    # Should respond to same methods as User
    expect(guest).to respond_to(:email)
    expect(guest).to respond_to(:name)
    expect(guest).to respond_to(:admin?)
    expect(guest).to respond_to(:discount_percentage)
  end
end

describe 'BookingService with users' do
  it 'calculates price for guest user' do
    guest = GuestUser.new
    price = service.calculate_price_for_user(guest, 100.0)
    expect(price).to eq(100.0)  # No discount
  end

  it 'calculates price for VIP user' do
    vip = User.new(email: 'vip@example.com', name: 'VIP', role: 'vip')
    price = service.calculate_price_for_user(vip, 100.0)
    expect(price).to eq(80.0)  # 20% discount
  end
end
```

---

## Exercise 4: Add Timeout Handling (ADVANCED)

**Goal:** Handle slow operations with timeouts

### Requirements

Add timeout support to prevent operations from hanging indefinitely.

### Implementation

```ruby
# lib/services/booking_service.rb

require 'timeout'

class BookingTimeoutError < BookingError
  def initialize(seconds)
    super("Booking operation timed out after #{seconds} seconds")
  end
end

def book_with_timeout(event_name, seats, timeout_seconds: 5)
  Timeout.timeout(timeout_seconds) do
    book!(event_name, seats)
  end
rescue Timeout::Error
  raise BookingTimeoutError.new(timeout_seconds)
rescue BookingError
  raise
end
```

### Tests to Write

```ruby
describe '#book_with_timeout' do
  context 'when operation completes in time' do
    it 'returns the booking' do
      booking = service.book_with_timeout('RubyConf 2026', 5, timeout_seconds: 5)
      expect(booking).to be_a(BookingService::Booking)
    end
  end

  context 'when operation times out' do
    it 'raises BookingTimeoutError' do
      # Simulate slow operation
      allow(service).to receive(:book!) do
        sleep(10)  # Longer than timeout
      end

      expect do
        service.book_with_timeout('RubyConf 2026', 5, timeout_seconds: 1)
      end.to raise_error(BookingTimeoutError, /timed out/)
    end
  end

  context 'when operation fails' do
    it 'raises the original error, not timeout' do
      allow(service).to receive(:book!)
        .and_raise(EventNotFoundError.new('Missing'))

      expect do
        service.book_with_timeout('Missing', 5, timeout_seconds: 5)
      end.to raise_error(EventNotFoundError)
    end
  end
end
```

---

## Exercise 5: Create Error Notification Service (ADVANCED)

**Goal:** Centralize error logging and notification

### Requirements

Create a service that logs errors and optionally notifies administrators.

### Implementation

```ruby
# lib/services/error_notification_service.rb

class ErrorNotificationService
  def initialize(logger: Logger.new(STDOUT), notifier: nil)
    @logger = logger
    @notifier = notifier
  end

  def notify(error, context = {})
    log_error(error, context)
    send_notification(error, context) if should_notify?(error)
  end

  private

  def log_error(error, context)
    @logger.error do
      {
        error_class: error.class.name,
        message: error.message,
        context: context,
        backtrace: error.backtrace&.first(5)
      }.to_json
    end
  end

  def send_notification(error, context)
    return unless @notifier

    @notifier.send_alert(
      title: "Error: #{error.class.name}",
      message: error.message,
      severity: severity_for(error),
      context: context
    )
  end

  def should_notify?(error)
    # Don't notify for expected failures
    !error.is_a?(ValidationError) && !error.is_a?(NotFoundError)
  end

  def severity_for(error)
    case error
    when EventSoldOutError, InsufficientSeatsError
      'medium'
    when BookingError
      'high'
    else
      'critical'
    end
  end
end
```

### Usage in BookingService

```ruby
class BookingService
  def initialize(repository, error_notifier: nil)
    @repository = repository
    @error_notifier = error_notifier || ErrorNotificationService.new
  end

  def book!(event_name, seats)
    book(event_name, seats).value
  rescue BookingError => e
    @error_notifier.notify(e, {
      event_name: event_name,
      requested_seats: seats,
      timestamp: Time.now
    })
    raise
  end
end
```

### Tests

```ruby
describe ErrorNotificationService do
  let(:logger) { double('Logger', error: nil) }
  let(:notifier) { double('Notifier', send_alert: nil) }
  subject(:service) { described_class.new(logger: logger, notifier: notifier) }

  describe '#notify' do
    let(:error) { EventSoldOutError.new('RubyConf') }
    let(:context) { { event: 'RubyConf', seats: 10 } }

    it 'logs the error' do
      expect(logger).to receive(:error)
      service.notify(error, context)
    end

    it 'sends notification for critical errors' do
      expect(notifier).to receive(:send_alert).with(
        hash_including(title: 'Error: EventSoldOutError')
      )
      service.notify(error, context)
    end

    it 'does not notify for validation errors' do
      validation_error = ValidationError.new('email', 'invalid')
      expect(notifier).not_to receive(:send_alert)
      service.notify(validation_error)
    end

    it 'includes context in log' do
      expect(logger).to receive(:error) do |&block|
        log_data = JSON.parse(block.call)
        expect(log_data['context']).to eq(context.stringify_keys)
      end
      service.notify(error, context)
    end
  end
end
```

---

## Exercise 6: Build BookingForm Object (EXPERT)

**Goal:** Handle form validation separate from models

### Requirements

Create a form object that validates booking form input and delegates to BookingService.

### Implementation

```ruby
# lib/forms/booking_form.rb

class BookingForm
  include Validatable

  attr_reader :event_name, :requested_seats, :customer_email, :errors

  def initialize(params = {})
    @event_name = params[:event_name]
    @requested_seats = params[:requested_seats]
    @customer_email = params[:customer_email]
    @errors = []
  end

  def valid?
    @errors = []

    validate_event_name
    validate_seats
    validate_email

    @errors.empty?
  end

  def submit(booking_service)
    return Result.failure(errors.join(', ')) unless valid?

    booking_service.book(event_name, requested_seats)
  end

  private

  def validate_event_name
    if event_name.nil? || event_name.empty?
      @errors << 'Event name is required'
    end
  end

  def validate_seats
    unless requested_seats.is_a?(Integer) && requested_seats.positive?
      @errors << 'Number of seats must be a positive number'
    end

    if requested_seats && requested_seats > 100
      @errors << 'Cannot book more than 100 seats at once'
    end
  end

  def validate_email
    unless customer_email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
      @errors << 'Email address is invalid'
    end
  end
end
```

### Tests

```ruby
describe BookingForm do
  let(:valid_params) do
    {
      event_name: 'RubyConf 2026',
      requested_seats: 5,
      customer_email: 'user@example.com'
    }
  end

  describe '#valid?' do
    it 'is valid with correct params' do
      form = described_class.new(valid_params)
      expect(form.valid?).to be true
    end

    it 'is invalid without event name' do
      form = described_class.new(valid_params.merge(event_name: ''))
      expect(form.valid?).to be false
      expect(form.errors).to include('Event name is required')
    end

    it 'is invalid with negative seats' do
      form = described_class.new(valid_params.merge(requested_seats: -5))
      expect(form.valid?).to be false
    end

    it 'is invalid with too many seats' do
      form = described_class.new(valid_params.merge(requested_seats: 150))
      expect(form.valid?).to be false
      expect(form.errors).to include('Cannot book more than 100 seats')
    end

    it 'is invalid with bad email' do
      form = described_class.new(valid_params.merge(customer_email: 'not-an-email'))
      expect(form.valid?).to be false
      expect(form.errors).to include('Email address is invalid')
    end
  end

  describe '#submit' do
    let(:service) { double('BookingService') }

    it 'submits to service when valid' do
      form = described_class.new(valid_params)

      expect(service).to receive(:book)
        .with('RubyConf 2026', 5)
        .and_return(Result.success('booking'))

      result = form.submit(service)
      expect(result).to be_success
    end

    it 'does not submit when invalid' do
      form = described_class.new(valid_params.merge(event_name: ''))

      expect(service).not_to receive(:book)

      result = form.submit(service)
      expect(result).to be_failure
    end
  end
end
```

---

## Bonus Exercise: Circuit Breaker Pattern (EXPERT)

**Goal:** Prevent cascading failures with circuit breaker

### Implementation

```ruby
# lib/patterns/circuit_breaker.rb

class CircuitBreaker
  class CircuitOpenError < StandardError; end

  STATES = [:closed, :open, :half_open].freeze

  def initialize(failure_threshold: 5, timeout: 60)
    @failure_threshold = failure_threshold
    @timeout = timeout
    @failure_count = 0
    @last_failure_time = nil
    @state = :closed
  end

  def call
    check_state

    begin
      result = yield
      on_success
      result
    rescue StandardError => e
      on_failure
      raise e
    end
  end

  private

  def check_state
    case @state
    when :open
      if Time.now - @last_failure_time > @timeout
        @state = :half_open
      else
        raise CircuitOpenError, 'Circuit breaker is open'
      end
    when :half_open
      # Allow one attempt
    end
  end

  def on_success
    @failure_count = 0
    @state = :closed
  end

  def on_failure
    @failure_count += 1
    @last_failure_time = Time.now

    if @failure_count >= @failure_threshold
      @state = :open
    end
  end
end
```

### Usage

```ruby
breaker = CircuitBreaker.new(failure_threshold: 3, timeout: 30)

begin
  breaker.call do
    external_api_call
  end
rescue CircuitBreaker::CircuitOpenError
  # Circuit is open, don't even try
  use_fallback_response
end
```

---

## Reflection Questions

1. **When should you use retry logic?**
   - Transient failures (network glitches)
   - NOT for permanent failures (validation errors)

2. **Result vs Exception - which did you prefer?**
   - Result forces explicit handling
   - Exceptions allow bubbling up

3. **What's the benefit of Null Object?**
   - No nil checks
   - Polymorphic behavior
   - Cleaner code

4. **Why separate forms from models?**
   - Forms handle UI validation
   - Models handle business rules
   - Single Responsibility

5. **When would you use a circuit breaker?**
   - External service calls
   - Prevent cascading failures
   - Give failing services time to recover

---

## Next Steps

1. ✅ Complete exercises 1-3 (core patterns)
2. ✅ Try exercises 4-5 (advanced handling)
3. ✅ Attempt exercise 6 (form objects)
4. ✅ Challenge: Implement circuit breaker
5. ✅ Ready for Day 5 - Value Objects!

**Remember:** Error handling is critical for production systems. Master these patterns and you'll write robust, maintainable code!
