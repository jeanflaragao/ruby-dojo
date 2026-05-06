require_relative 'application_record'
class Venue < ApplicationRecord
  # Associations
  has_many :events
  
  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :address, presence: true
  validates :capacity, presence: true, numericality: { greater_than: 0 }
end