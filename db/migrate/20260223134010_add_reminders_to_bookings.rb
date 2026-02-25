class AddRemindersToBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :reminder_enabled, :boolean, default: true, null: false
    add_column :bookings, :reminder_minutes_before, :integer, default: 60, null: false
  end
end
