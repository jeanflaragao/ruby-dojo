class AddEventIdToBookings < ActiveRecord::Migration[7.2]
  def change
    add_reference :bookings, :event, null: false, foreign_key: true
  end
end