# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.text :description
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.integer :total_seats, null: false
      t.integer :available_seats, null: false

      # Money value object columns (ADD THESE!)
      t.decimal :base_price_amount, precision: 10, scale: 2
      t.string :base_price_currency, default: 'USD'

      # Foreign key to venues
      t.references :venue, null: false, foreign_key: true

      t.timestamps
    end

    # Indexes
    add_index :events, :name
    add_index :events, :start_time
  end
end