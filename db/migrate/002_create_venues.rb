# frozen_string_literal: true

class CreateVenues < ActiveRecord::Migration[7.0]
  def change
    create_table :venues do |t|
      t.string :name, null: false
      t.string :address, null: false
      t.integer :capacity, null: false

      t.timestamps
    end

    add_index :venues, :name
  end
end
