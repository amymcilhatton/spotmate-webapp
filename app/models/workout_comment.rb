class WorkoutComment < ApplicationRecord
  belongs_to :workout_log
  belongs_to :author, class_name: "User"

  validates :body, presence: true
end
