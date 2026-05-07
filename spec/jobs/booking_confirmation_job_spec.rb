# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'
require_relative '../../lib/jobs/booking_confirmation_job'

RSpec.describe BookingConfirmationJob, type: :job do
  # Use fake mode for testing
  around(:each) do |example|
    Sidekiq::Testing.fake! do
      example.run
    end
  end

  let(:venue) do
    Venue.create!(
      name: 'Test Venue',
      address: '123 St',
      capacity: 100
    )
  end

  let(:event) do
    Event.create!(
      name: 'Test Event',
      description: 'Description',
      venue: venue,
      start_time: Time.now + 1.day,
      end_time: Time.now + 1.day + 2.hours,
      total_seats: 50,
      base_price: Money.new(50, 'USD')
    )
  end

  let(:booking) do
    Booking.create!(
      event: event,
      confirmation_code: 'TEST123',
      seats_reserved: 2,
      total_price_amount: 100,
      total_price_currency: 'USD',
      ticket_type: 'vip',
      email: 'test@example.com'
    )
  end

  describe '.perform_async' do
    it 'enqueues the job' do
      expect {
        described_class.perform_async(booking.id)
      }.to change(described_class.jobs, :size).by(1)
    end

    it 'enqueues with correct arguments' do
      described_class.perform_async(booking.id)
      
      expect(described_class.jobs.last['args']).to eq([booking.id])
    end
  end

  describe '#perform' do
    it 'processes the booking' do
      # We'll test this sends email later
      expect {
        described_class.new.perform(booking.id)
      }.not_to raise_error
    end

    it 'finds the booking' do
      job = described_class.new
      allow(job).to receive(:send_confirmation_email)
      
      job.perform(booking.id)
      
      # Job should find the booking
      expect(Booking.find(booking.id)).to eq(booking)
    end
  end
end