class Match < ApplicationRecord
  belongs_to :user_a, class_name: "User"
  belongs_to :user_b, class_name: "User"
  has_many :bookings, dependent: :destroy
  has_many :match_decisions, dependent: :destroy

  enum status: { pending: 0, accepted: 1, declined: 2 }, _prefix: true

  def other_user(user)
    user.id == user_a_id ? user_b : user_a
  end
end
