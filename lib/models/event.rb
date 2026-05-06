# frozen_string_literal: true

require_relative 'application_record'
require_relative '../value_objects/money'

class Event < ApplicationRecord
  # Associations
  belongs_to :venue

  has_many :bookings, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :description, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :total_seats, numericality: { greater_than: 0 }
  validates :available_seats, numericality: { greater_than_or_equal_to: 0 }
  validate :end_time_after_start_time

  # Callbacks
  before_validation :set_available_seats, on: :create

  scope :upcoming, -> { where('start_time > ?', Time.now) }
  scope :available, -> { where('available_seats > 0') }

  # Value object wrapper for Money
  def base_price
    Money.new(base_price_amount, base_price_currency)
  end

  def base_price=(money)
    self.base_price_amount = money.amount
    self.base_price_currency = money.currency
  end

  # Business logic
  def reserve_seats(seats)
    raise ArgumentError, 'Not enough seats' if seats > available_seats
    
    self.available_seats -= seats
    save!
  end

  def sold_out?
    available_seats.zero?
  end

  def duration_in_hours
    ((end_time - start_time) / 3600.0).round(2)
  end

  private

  def set_available_seats
    self.available_seats ||= total_seats
  end

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, 'must be after start time')
    end
  end
end