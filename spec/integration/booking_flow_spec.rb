# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Complete Booking Flow' do
  let(:venue) do
    Venue.new(
      name: 'Convention Center',
      address: '123 Main St',
      capacity: 500
    )
  end

  let(:event) do
    Event.new(
      name: 'RubyConf 2026',
      description: 'Ruby conference',
      venue: venue,
      start_time: Time.new(2026, 6, 15, 9, 0, 0),
      end_time: Time.new(2026, 6, 17, 18, 0, 0),
      total_seats: 100,
      base_price: Money.new(100, 'USD')
    )
  end

  let(:repository) { EventRepository.new([event]) }
  let(:service) { BookingService.new(repository) }

  it 'books tickets with VIP pricing' do
    # 1. User fills form
    form = BookingForm.new(
      event_name: 'RubyConf 2026',
      seats: '2',
      ticket_type: 'vip',
      email: 'user@example.com'
    )

    # 2. Form validates
    expect(form).to be_valid

    # 3. Service processes booking
    result = service.book_with_form(form)

    # 4. Booking succeeds
    expect(result).to be_success

    # 5. Price calculated correctly
    booking = result.value
    expect(booking.total_price).to eq(Money.new(400, 'USD')) # 2 * 200
    expect(booking.ticket_type).to be_a(VIPTicket)
    expect(booking.seats_reserved).to eq(2)
  end

  it 'validates form before booking' do
    # Invalid form (negative seats)
    form = BookingForm.new(
      event_name: 'RubyConf 2026',
      seats: '-5',
      ticket_type: 'general',
      email: 'user@example.com'
    )

    form.valid?

    expect(form.errors[:seats]).to include('must be positive')

    result = service.book_with_form(form)

    expect(result).to be_failure
    expect(result.error[:seats]).to include('must be positive')
  end

  it 'handles event not found' do
    form = BookingForm.new(
      event_name: 'NonExistent',
      seats: '2',
      ticket_type: 'general',
      email: 'user@example.com'
    )

    form.valid?

    result = service.book_with_form(form)

    expect(result).to be_failure
    expect(result.error).to include('not found')
  end
end
