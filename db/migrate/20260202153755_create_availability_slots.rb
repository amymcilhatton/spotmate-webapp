class CreateAvailabilitySlots < ActiveRecord::Migration[7.1]
  def change
    create_table :availability_slots do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :dow
      t.integer :start_min
      t.integer :end_min

      t.timestamps
    end
  end
end
