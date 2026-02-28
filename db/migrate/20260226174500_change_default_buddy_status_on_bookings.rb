class ChangeDefaultBuddyStatusOnBookings < ActiveRecord::Migration[7.1]
  def change
    change_column_default :bookings, :buddy_status, from: 1, to: 0
  end
end
