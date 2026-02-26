class AddNotesToWorkoutLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :workout_logs, :notes, :text
  end
end
