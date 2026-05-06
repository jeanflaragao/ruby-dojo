require 'active_record'
require_relative '../value_objects/money'

class Booking < ActiveRecord::Base
  # Associations
  belongs_to :event

  before_validation :generate_confirmation_code, on: :create
  
  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :seats_reserved, presence: true, numericality: { greater_than: 0 }
  validates :ticket_type, presence: true, inclusion: { in: %w[general vip student] }
  validates :total_price_amount, presence: true, numericality: { greater_than: 0 }
  
  # Money value object getter
  def total_price
    Money.new(total_price_amount, total_price_currency) if total_price_amount && total_price_currency
  end
  
  # Money value object setter
  def total_price=(money)
    if money.is_a?(Money)
      self.total_price_amount = money.amount
      self.total_price_currency = money.currency
    end
  end

  private

  def generate_confirmation_code
    self.confirmation_code ||= SecureRandom.hex(4).upcase # Generates something like "A1B2C3D4"
  end
  
end