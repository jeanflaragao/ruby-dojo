# frozen_string_literal: true

class BookingForm
  VALID_TICKET_TYPES = %w[vip general student].freeze
  MAX_SEATS_PER_BOOKING = 10
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i

  attr_reader :event_name, :seats, :ticket_type, :email, :errors

  def initialize(params = {})
    @event_name = params[:event_name]
    @seats = params[:seats]
    @ticket_type = params[:ticket_type]
    @email = params[:email]
    @errors = {}
  end

  # Validates the form - returns true/false
  def valid?
    @errors = {}

    validate_event_name
    validate_seats
    validate_ticket_type
    validate_email

    @errors.empty?
  end

  # Returns validated and coerced attributes
  def to_h
    {
      event_name: event_name,
      seats: seats.to_i,
      ticket_type: ticket_type.to_sym,
      email: email
    }
  end

  # Human-readable error messages
  def error_messages
    errors.flat_map do |field, messages|
      messages.map { |msg| "#{field.to_s.capitalize.tr('_', ' ')} #{msg}" }
    end
  end

  private

  def validate_event_name
    return unless blank?(event_name)

    add_error(:event_name, "can't be blank")
  end

  def validate_seats
    if blank?(seats)
      add_error(:seats, "can't be blank")
      return
    end

    # Check if numeric
    unless numeric?(seats)
      add_error(:seats, 'must be a number')
      return
    end

    seats_int = seats.to_i

    # Check if positive
    add_error(:seats, 'must be positive') unless seats_int.positive?

    # Check maximum
    return unless seats_int > MAX_SEATS_PER_BOOKING

    add_error(:seats, "cannot exceed #{MAX_SEATS_PER_BOOKING} per booking")
  end

  def validate_ticket_type
    if blank?(ticket_type)
      add_error(:ticket_type, "can't be blank")
      return
    end

    return if VALID_TICKET_TYPES.include?(ticket_type.to_s.downcase)

    add_error(:ticket_type, "must be one of: #{VALID_TICKET_TYPES.join(', ')}")
  end

  def validate_email
    if blank?(email)
      add_error(:email, "can't be blank")
      return
    end

    return if email.match?(EMAIL_REGEX)

    add_error(:email, 'must be a valid email address')
  end

  # Helper methods

  def blank?(value)
    value.nil? || value.to_s.strip.empty?
  end

  def numeric?(value)
    true if Integer(value)
  rescue ArgumentError, TypeError
    false
  end

  def add_error(field, message)
    @errors[field] ||= []
    @errors[field] << message
  end
end
