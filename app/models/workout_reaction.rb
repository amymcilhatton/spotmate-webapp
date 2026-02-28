class WorkoutReaction < ApplicationRecord
  enum kind: { kudos: "kudos", comment: "comment" }

  belongs_to :user
  belongs_to :workout_log

  validates :kind, presence: true, inclusion: { in: kinds.keys }
  validates :body, presence: true, if: :comment?
end
