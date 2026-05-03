# VALUE OBJECTS & FORM OBJECTS - QUICK REFERENCE

## Value Object Checklist

```ruby
class MyValueObject
  attr_reader :attribute1, :attribute2

  def initialize(attribute1, attribute2)
    # 1. Validate inputs
    raise ArgumentError unless valid_input?(attribute1)

    # 2. Set instance variables
    @attribute1 = attribute1
    @attribute2 = attribute2

    # 3. FREEZE! (immutability)
    freeze
  end

  # 4. Value equality
  def ==(other)
    return false unless other.is_a?(MyValueObject)
    attribute1 == other.attribute1 && attribute2 == other.attribute2
  end

  alias eql? ==

  # 5. Hash support (for hash keys)
  def hash
    [attribute1, attribute2].hash
  end

  # 6. Operations return NEW instances
  def some_operation
    MyValueObject.new(modified_attr1, modified_attr2)
  end

  # 7. Formatting
  def to_s
    "#{attribute1} - #{attribute2}"
  end

  def to_h
    { attribute1: attribute1, attribute2: attribute2 }
  end
end
```

---

## Form Object Checklist

```ruby
class MyForm
  attr_reader :field1, :field2, :errors

  def initialize(params = {})
    # 1. Accept raw params (don't coerce yet)
    @field1 = params[:field1]
    @field2 = params[:field2]
    @errors = {}
  end

  # 2. Validation method
  def valid?
    @errors = {}

    validate_field1
    validate_field2

    @errors.empty?
  end

  # 3. Return coerced/typed data
  def to_h
    {
      field1: field1.to_i,        # String → Integer
      field2: field2.to_sym       # String → Symbol
    }
  end

  # 4. User-friendly errors
  def error_messages
    errors.flat_map do |field, messages|
      messages.map { |msg| "#{field.to_s.capitalize} #{msg}" }
    end
  end

  private

  def validate_field1
    if blank?(field1)
      add_error(:field1, "can't be blank")
    elsif !numeric?(field1)
      add_error(:field1, 'must be a number')
    end
  end

  def blank?(value)
    value.nil? || value.to_s.strip.empty?
  end

  def add_error(field, message)
    @errors[field] ||= []
    @errors[field] << message
  end
end
```

---

## Common Patterns

### Money Value Object

```ruby
class Money
  attr_reader :amount, :currency

  def initialize(amount, currency = 'USD')
    raise ArgumentError unless amount.positive?
    @amount = amount
    @currency = currency
    freeze
  end

  def +(other)
    ensure_same_currency!(other)
    Money.new(amount + other.amount, currency)
  end

  def *(multiplier)
    Money.new(amount * multiplier, currency)
  end

  def to_s
    format('%.2f %s', amount, currency)
  end
end
```

### DateRange Value Object

```ruby
class DateRange
  attr_reader :start_date, :end_date

  def initialize(start_date, end_date)
    raise ArgumentError if start_date > end_date
    @start_date = start_date
    @end_date = end_date
    freeze
  end

  def days
    (end_date - start_date).to_i + 1
  end

  def includes?(date)
    date >= start_date && date <= end_date
  end

  def overlaps?(other)
    start_date <= other.end_date && end_date >= other.start_date
  end
end
```

### Address Value Object

```ruby
class Address
  attr_reader :street, :city, :state, :zip

  def initialize(street:, city:, state:, zip:)
    @street = street
    @city = city
    @state = state
    @zip = zip
    freeze
  end

  def to_s
    "#{street}, #{city}, #{state} #{zip}"
  end
end
```

---

## Testing Patterns

### Value Object Tests

```ruby
RSpec.describe Money do
  it 'is frozen' do
    money = Money.new(100, 'USD')
    expect(money).to be_frozen
  end

  it 'has value equality' do
    m1 = Money.new(100, 'USD')
    m2 = Money.new(100, 'USD')
    expect(m1).to eq(m2)
  end

  it 'can be used as hash key' do
    hash = { Money.new(100, 'USD') => 'price' }
    expect(hash[Money.new(100, 'USD')]).to eq('price')
  end

  it 'returns new instance from operations' do
    original = Money.new(100, 'USD')
    result = original * 2
    expect(result).not_to equal(original)
    expect(original.amount).to eq(100)
  end
end
```

### Form Object Tests

```ruby
RSpec.describe BookingForm do
  it 'validates presence' do
    form = BookingForm.new(name: '')
    expect(form).not_to be_valid
    expect(form.errors[:name]).to include("can't be blank")
  end

  it 'coerces types' do
    form = BookingForm.new(seats: '5')
    expect(form.to_h[:seats]).to eq(5)
    expect(form.to_h[:seats]).to be_a(Integer)
  end

  it 'collects multiple errors' do
    form = BookingForm.new(seats: 'abc', email: 'bad')
    expect(form).not_to be_valid
    expect(form.errors.keys).to include(:seats, :email)
  end
end
```

---

## When to Use

### Use Value Objects When:

✓ Representing domain concepts (Money, DateRange, Address)
✓ Need validation on construction
✓ Want immutability
✓ Need value equality
✓ Preventing primitive obsession
✓ Encapsulating domain rules

### Use Form Objects When:

✓ Accepting user input
✓ Need validation before business logic
✓ Coercing types (strings → proper types)
✓ Working with web forms/APIs
✓ Validating complex multi-model forms
✓ Want user-friendly error messages

---

## Anti-Patterns

### ❌ DON'T: Mutable Value Objects

```ruby
class Money
  attr_accessor :amount  # NO! Should be attr_reader
  # Missing freeze
end
```

### ❌ DON'T: Business Logic in Forms

```ruby
class BookingForm
  def process_booking
    BookingService.book(...)  # NO! Form should only validate
  end
end
```

### ❌ DON'T: Identity Equality for Value Objects

```ruby
m1 = Money.new(100, 'USD')
m2 = Money.new(100, 'USD')
m1.equal?(m2)  # false - WRONG comparison for value objects
m1 == m2       # true - CORRECT
```

### ❌ DON'T: Mutating Operations

```ruby
class Money
  def add(other)
    @amount += other.amount  # NO! Violates immutability
  end
end

# ✅ DO: Return new instance
def +(other)
  Money.new(amount + other.amount, currency)
end
```

---

## Workflow

### With Value Objects

```ruby
# 1. Create value objects
price = Money.new(100, 'USD')
quantity = 3

# 2. Operations return new instances
total = price * quantity  # => Money.new(300, 'USD')

# 3. Safe to pass around (immutable)
process_payment(total)
```

### With Form Objects

```ruby
# 1. Accept raw params
form = BookingForm.new(params)

# 2. Validate
if form.valid?
  # 3. Get clean, coerced data
  data = form.to_h

  # 4. Pass to business logic
  BookingService.book(data)
else
  # 5. Return user-friendly errors
  render json: { errors: form.error_messages }
end
```

---

## Remember

**Value Objects:**

- Immutable (freeze)
- Value equality (==)
- Return new instances
- Domain rules enforced

**Form Objects:**

- Validate raw input
- Coerce types
- Separate from business logic
- User-friendly errors

**Both:**

- Make invalid states unrepresentable
- Encapsulate logic in one place
- Make code more expressive
- Easier to test
