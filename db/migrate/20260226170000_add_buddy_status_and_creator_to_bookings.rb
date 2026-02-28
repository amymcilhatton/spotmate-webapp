class AddBuddyStatusAndCreatorToBookings < ActiveRecord::Migration[7.1]
  def up
    add_reference :bookings, :creator, foreign_key: { to_table: :users }
    add_column :bookings, :buddy_status, :integer, null: false, default: 1

    execute <<~SQL
      UPDATE bookings
      SET creator_id = matches.user_a_id
      FROM matches
      WHERE bookings.match_id = matches.id AND bookings.creator_id IS NULL
    SQL

    change_column_null :bookings, :creator_id, false
  end

  def down
    change_column_null :bookings, :creator_id, true
    remove_column :bookings, :buddy_status
    remove_reference :bookings, :creator, foreign_key: { to_table: :users }
  end
end
