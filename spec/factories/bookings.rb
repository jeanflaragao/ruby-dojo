FactoryBot.define do
  factory :booking do
    association :event
    sequence(:email) { |n| "user#{n}@example.com" }
    seats_reserved { 2 }
    ticket_type { 'general' }
    total_price_amount { 200.00 }  # Matches your schema (decimal)
    total_price_currency { 'USD' }
    confirmation_code { SecureRandom.hex(8) }

    trait :confirmed do
      confirmation_code { "CONFIRMED-#{SecureRandom.hex(6)}" }
    end

    trait :vip do
      ticket_type { 'vip' }
      total_price_amount { 500.00 }
    end

    trait :large_group do
      seats_reserved { 10 }
      total_price_amount { 1000.00 }
    end
  end
end