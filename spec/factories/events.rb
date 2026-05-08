FactoryBot.define do
  factory :event do
    name { "Ruby Conference" }
    description { "Annual Ruby conference" }
    start_time { 30.days.from_now }
    end_time { 33.days.from_now }
    total_seats { 500 }
    available_seats { 500 }
    base_price_amount { 100.00 }  # Matches your schema (decimal)
    base_price_currency { 'USD' }
    association :venue

    trait :sold_out do
      available_seats { 0 }
    end

    trait :past do
      start_time { 30.days.ago }
      end_time { 27.days.ago }
    end

    trait :expensive do
      base_price_amount { 500.00 }
    end

    trait :with_bookings do
      after(:create) do |event|
        create_list(:booking, 5, event: event)
      end
    end
  end
end