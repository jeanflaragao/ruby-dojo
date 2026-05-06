class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.string :confirmation_code, null: false
      t.integer :seats_reserved, null: false
      t.decimal :total_price_amount, precision: 10, scale: 2
      t.string :total_price_currency, default: 'USD'
      t.string :email, null: false
      
      t.timestamps  # created_at, updated_at
    end
  end
end