# frozen_string_literal: true

class EventForm
  REQUIRED_FIELDS = %i[name description venue_name start_time end_time total_seats base_price].freeze

  attr_reader :name, :description, :venue_name, :start_time, :end_time, :total_seats, :base_price, :errors

  def initialize(params = {})
    @name        = params[:name]
    @description = params[:description]
    @venue_name  = params[:venue_name]
    @start_time  = params[:start_time]
    @end_time    = params[:end_time]
    @total_seats = params[:total_seats]
    @base_price  = params[:base_price]
    @errors      = {}
  end

  def valid?
    @errors = {}

    REQUIRED_FIELDS.each { |field| validate_presence(field) }
    validate_time_range
    validate_positive(:total_seats)
    validate_positive(:base_price)

    errors.empty?
  end

  def to_h
    {
      name: name,
      description: description,
      venue_name: venue_name,
      start_time: Time.parse(start_time),
      end_time: Time.parse(end_time),
      total_seats: total_seats.to_i,
      base_price: Money.new(base_price.to_f)
    }
  end

  private

  def add_error(field, message)
    errors[field] ||= []
    errors[field] << message
  end

  def validate_presence(field)
    value = send(field)
    add_error(field, "can't be blank") if value.nil? || value.to_s.strip.empty?
  end

  def validate_time_range
    return unless start_time && end_time

    begin
      start_t = Time.parse(start_time)
      end_t = Time.parse(end_time)
      add_error(:end_time, 'must be after start time') if end_t <= start_t
    rescue ArgumentError
      add_error(:start_time, 'is not a valid datetime')
    end
  end

  def validate_positive(field)
    value = send(field)
    return unless value

    add_error(field, 'must be positive') if value.to_f <= 0
  end
end
