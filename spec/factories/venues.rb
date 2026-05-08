FactoryBot.define do
  factory :venue do
    name { "Convention Center" }
    address { "123 Main St, San Francisco, CA" }
    capacity { 1000 }

    trait :small do
      name { "Community Hall" }
      capacity { 50 }
    end

    trait :large do
      name { "Stadium" }
      capacity { 5000 }
    end

    trait :with_events do
      after(:create) do |venue|
        create_list(:event, 3, venue: venue)
      end
    end
  end
end