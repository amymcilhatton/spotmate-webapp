class CreateWorkoutKudos < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_kudos do |t|
      t.references :workout_log, null: false, foreign_key: true
      t.references :giver, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :workout_kudos, %i[workout_log_id giver_id], unique: true
  end
end
