class AllowNullMatchIdOnBookings < ActiveRecord::Migration[7.1]
  def change
    change_column_null :bookings, :match_id, true
  end
end
