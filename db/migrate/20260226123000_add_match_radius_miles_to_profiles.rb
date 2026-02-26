class AddMatchRadiusMilesToProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :match_radius_miles, :integer, default: 50, null: false
  end
end
