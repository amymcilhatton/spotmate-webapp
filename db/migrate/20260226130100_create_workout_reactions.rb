class CreateWorkoutReactions < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workout_log, null: false, foreign_key: true
      t.string :kind, null: false
      t.text :body

      t.timestamps
    end

    add_index :workout_reactions,
              %i[user_id workout_log_id],
              unique: true,
              where: "kind = 'kudos'",
              name: "index_workout_reactions_on_user_log_kudos"
  end
end
