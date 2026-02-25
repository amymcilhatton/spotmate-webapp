class CreateWorkoutLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date
      t.integer :kind
      t.jsonb :payload_json

      t.timestamps
    end
  end
end
