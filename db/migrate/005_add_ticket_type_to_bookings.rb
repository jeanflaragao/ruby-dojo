class AddTicketTypeToBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :bookings, :ticket_type, :string
  end
end