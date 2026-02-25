class AddBuddyFieldsToWorkoutLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :workout_logs, :title, :string
    add_column :workout_logs, :exercises, :jsonb, default: [], null: false
    add_column :workout_logs, :shared_with_buddies, :boolean, default: false, null: false
    add_column :workout_logs, :contains_pr, :boolean, default: false, null: false
  end
end
