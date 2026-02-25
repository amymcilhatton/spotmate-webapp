class CreateWorkoutComments < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_comments do |t|
      t.references :workout_log, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false

      t.timestamps
    end
  end
end
