class AddGymFieldsToProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :gym_postcode, :string
    add_column :profiles, :gym_latitude, :decimal, precision: 10, scale: 6
    add_column :profiles, :gym_longitude, :decimal, precision: 10, scale: 6
  end
end
