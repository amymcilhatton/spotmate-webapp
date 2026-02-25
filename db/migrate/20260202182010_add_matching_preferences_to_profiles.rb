class AddMatchingPreferencesToProfiles < ActiveRecord::Migration[7.1]
  def change
    change_table :profiles, bulk: true do |t|
      t.integer :age
      t.string :home_gym_name
      t.string :home_city
      t.string :travel_preference, default: "flexible", null: false
      t.integer :preferred_partner_age_min
      t.integer :preferred_partner_age_max
      t.string :preferred_buddy_days, array: true, default: [], null: false
      t.string :preferred_buddy_times, array: true, default: [], null: false
    end
  end
end
