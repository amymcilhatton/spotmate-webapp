class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.references :match, null: false
      t.datetime :start_at
      t.datetime :end_at
      t.integer :status

      t.timestamps
    end
  end
end
