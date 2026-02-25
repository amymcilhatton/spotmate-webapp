class WorkoutLog < ApplicationRecord
  belongs_to :user

  enum kind: { strength: 0, conditioning: 1, skills: 2 }, _prefix: true

  has_many :workout_comments, dependent: :destroy
  has_many :workout_kudos, dependent: :destroy
end
