# frozen_string_literal: true

class CreateVenues < ActiveRecord::Migration[7.1]
  def change
    create_table :venues do |t|
      t.string :name, null: false
      t.string :address
      t.integer :capacity, null: false

      t.timestamps  # Creates created_at and updated_at columns
    end

    # Add indexes for common queries
    add_index :venues, :name
  end
end