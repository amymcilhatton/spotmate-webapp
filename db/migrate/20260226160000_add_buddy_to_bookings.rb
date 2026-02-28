class AddBuddyToBookings < ActiveRecord::Migration[7.1]
  def change
    add_reference :bookings, :buddy, null: true, foreign_key: { to_table: :users }
  end
end
