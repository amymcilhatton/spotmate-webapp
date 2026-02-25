class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :age_range
      t.string :gender
      t.string :gym
      t.integer :experience_band
      t.string :goals, array: true, default: []
      t.boolean :women_only, default: false, null: false
      t.boolean :same_gym_only, default: false, null: false
      t.integer :minimum_weekly_overlap_minutes, default: 90, null: false
      t.jsonb :privacy_matrix, default: {}, null: false

      t.timestamps
    end
  end
end
