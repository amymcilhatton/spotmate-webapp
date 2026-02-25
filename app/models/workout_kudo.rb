class WorkoutKudo < ApplicationRecord
  belongs_to :workout_log
  belongs_to :giver, class_name: "User"
end
