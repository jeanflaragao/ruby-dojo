# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/forms/booking_form'

RSpec.describe BookingForm do
  describe 'initialization' do
    it 'accepts form parameters' do
      form = BookingForm.new(
        event_name: 'Ruby Conference',
        seats: '3',
        ticket_type: 'vip',
        email: 'user@example.com'
      )

      expect(form.event_name).to eq('Ruby Conference')
      expect(form.seats).to eq('3')
      expect(form.ticket_type).to eq('vip')
      expect(form.email).to eq('user@example.com')
    end

    it 'handles nil/missing parameters gracefully' do
      form = BookingForm.new({})
      expect(form.event_name).to be_nil
      expect(form.seats).to be_nil
    end
  end

  describe 'validation' do
    describe 'event_name' do
      it 'is valid with event name present' do
        form = BookingForm.new(
          event_name: 'Conference',
          seats: '2',
          ticket_type: 'general',
          email: 'user@example.com'
        )
        expect(form).to be_valid
      end

      it 'is invalid when event_name is blank' do
        form = BookingForm.new(seats: '2', ticket_type: 'general', email: 'user@example.com')
        expect(form).not_to be_valid
        expect(form.errors[:event_name]).to include("can't be blank")
      end

      it 'is invalid when event_name is empty string' do
        form = BookingForm.new(event_name: '', seats: '2', ticket_type: 'general', email: 'user@example.com')
        expect(form).not_to be_valid
      end
    end

    describe 'seats' do
      it 'is invalid when seats is blank' do
        form = BookingForm.new(event_name: 'Conference', ticket_type: 'general', email: 'user@example.com')
        expect(form).not_to be_valid
        expect(form.errors[:seats]).to include("can't be blank")
      end

      it 'is invalid when seats is not a number' do
        form = BookingForm.new(event_name: 'Conference', seats: 'abc', ticket_type: 'general', email: 'user@example.com')
        expect(form).not_to be_valid
        expect(form.errors[:seats]).to include('must be a number')
      end

      it 'is invalid when seats is negative' do
        form = BookingForm.new(event_name: 'Conference', seats: '-1', ticket_type: 'general', email: 'user@example.com')
        expect(form).not_to be_valid
        expect(form.errors[:seats]).to include('must be positive')
      end

      it 'is invalid when seats is zero' do
        form = BookingForm.new(event_name: 'Conference', seats: '0', ticket_type: 'general', email: 'user@example.com')
        expect(form).not_to be_valid
        expect(form.errors[:seats]).to include('must be positive')
      end

      it 'is invalid when seats exceeds maximum (10)' do
        form = BookingForm.new(event_name: 'Conference', seats: '11', ticket_type: 'general', email: 'user@example.com')
        expect(form).not_to be_valid
        expect(form.errors[:seats]).to include('cannot exceed 10 per booking')
      end
    end

    describe 'ticket_type' do
      it 'is valid with vip ticket type' do
        form = BookingForm.new(event_name: 'Conference', seats: '2', ticket_type: 'vip', email: 'user@example.com')
        expect(form).to be_valid
      end

      it 'is valid with general ticket type' do
        form = BookingForm.new(event_name: 'Conference', seats: '2', ticket_type: 'general', email: 'user@example.com')
        expect(form).to be_valid
      end

      it 'is valid with student ticket type' do
        form = BookingForm.new(event_name: 'Conference', seats: '2', ticket_type: 'student', email: 'user@example.com')
        expect(form).to be_valid
      end

      it 'is invalid with unknown ticket type' do
        form = BookingForm.new(event_name: 'Conference', seats: '2', ticket_type: 'premium', email: 'user@example.com')
        expect(form).not_to be_valid
        expect(form.errors[:ticket_type]).to include('must be one of: vip, general, student')
      end

      it 'is invalid when ticket_type is blank' do
        form = BookingForm.new(event_name: 'Conference', seats: '2', email: 'user@example.com')
        expect(form).not_to be_valid
      end
    end

    describe 'email' do
      it 'is valid with proper email format' do
        form = BookingForm.new(event_name: 'Conference', seats: '2', ticket_type: 'general', email: 'user@example.com')
        expect(form).to be_valid
      end

      it 'is invalid when email is blank' do
        form = BookingForm.new(event_name: 'Conference', seats: '2', ticket_type: 'general')
        expect(form).not_to be_valid
        expect(form.errors[:email]).to include("can't be blank")
      end

      it 'is invalid with improper email format' do
        form = BookingForm.new(event_name: 'Conference', seats: '2', ticket_type: 'general', email: 'notanemail')
        expect(form).not_to be_valid
        expect(form.errors[:email]).to include('must be a valid email address')
      end
    end

    describe 'multiple errors' do
      it 'collects all validation errors' do
        form = BookingForm.new(seats: 'abc', ticket_type: 'invalid', email: 'bad')
        expect(form).not_to be_valid
        expect(form.errors.keys).to include(:event_name, :seats, :ticket_type, :email)
      end
    end
  end

  describe '#to_h' do
    it 'returns coerced attributes for valid form' do
      form = BookingForm.new(
        event_name: 'Conference',
        seats: '3',
        ticket_type: 'vip',
        email: 'user@example.com'
      )

      expect(form.to_h).to eq({
                                event_name: 'Conference',
                                seats: 3, # Coerced to integer
                                ticket_type: :vip, # Coerced to symbol
                                email: 'user@example.com'
                              })
    end
  end

  describe '#error_messages' do
    it 'returns human-readable error messages' do
      form = BookingForm.new(seats: 'abc')
      form.valid?

      messages = form.error_messages
      expect(messages).to be_an(Array)
      expect(messages).to include("Event name can't be blank")
      expect(messages).to include('Seats must be a number')
    end
  end
end