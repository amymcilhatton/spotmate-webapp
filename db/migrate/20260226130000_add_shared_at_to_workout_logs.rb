class AddSharedAtToWorkoutLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :workout_logs, :shared_at, :datetime
  end
end
