class AddLocationNameToAvailabilitySlots < ActiveRecord::Migration[7.1]
  def change
    add_column :availability_slots, :location_name, :string
  end
end
